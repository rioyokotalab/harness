#!/usr/bin/env python3
"""Bounded PyTorch forward/backward smoke for a selected project environment."""

from __future__ import annotations

import argparse
import math
import os


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run a tiny deterministic language-model forward/backward step in "
            "an already-selected PyTorch environment."
        )
    )
    parser.add_argument(
        "--device",
        choices=("auto", "cpu", "cuda"),
        default="auto",
        help="execution device; auto selects CUDA only when PyTorch exposes it",
    )
    parser.add_argument(
        "--require-world-size",
        type=int,
        help="fail unless WORLD_SIZE has this exact positive value",
    )
    return parser.parse_args()


def environment_integer(name: str, default: int) -> int:
    raw = os.environ.get(name, str(default))
    try:
        value = int(raw)
    except ValueError as error:
        raise SystemExit(f"llm_torch_smoke: invalid {name}={raw!r}") from error
    if value < 0:
        raise SystemExit(f"llm_torch_smoke: {name} must be non-negative")
    return value


def main() -> None:
    args = parse_args()
    if args.require_world_size is not None and args.require_world_size < 1:
        raise SystemExit("llm_torch_smoke: --require-world-size must be positive")

    try:
        import torch
        import torch.distributed as dist
        import torch.nn.functional as functional
        from torch import nn
        from torch.nn.parallel import DistributedDataParallel
    except ImportError as error:
        raise SystemExit(
            "llm_torch_smoke: PyTorch is absent; enter the project's locked "
            "environment or reviewed site image first"
        ) from error

    world_size = environment_integer("WORLD_SIZE", 1)
    rank = environment_integer("RANK", 0)
    local_rank = environment_integer("LOCAL_RANK", 0)
    if world_size < 1 or rank >= world_size:
        raise SystemExit("llm_torch_smoke: invalid rank/world-size relationship")
    if args.require_world_size is not None and world_size != args.require_world_size:
        raise SystemExit(
            "llm_torch_smoke: expected world size "
            f"{args.require_world_size}, observed {world_size}"
        )

    want_cuda = args.device == "cuda" or (
        args.device == "auto" and torch.cuda.is_available()
    )
    if want_cuda and not torch.cuda.is_available():
        raise SystemExit("llm_torch_smoke: CUDA requested but unavailable to PyTorch")
    if want_cuda:
        device_index = local_rank if world_size > 1 else 0
        torch.cuda.set_device(device_index)
        device = torch.device("cuda", device_index)
        backend = "nccl"
    else:
        device = torch.device("cpu")
        backend = "gloo"

    initialized = False
    try:
        if world_size > 1:
            if not dist.is_available():
                raise SystemExit("llm_torch_smoke: torch.distributed is unavailable")
            dist.init_process_group(backend=backend, init_method="env://")
            initialized = True
            observed_rank = dist.get_rank()
            observed_world_size = dist.get_world_size()
            if (observed_rank, observed_world_size) != (rank, world_size):
                raise SystemExit("llm_torch_smoke: process-group metadata mismatch")
            rank_value = torch.tensor(rank, device=device, dtype=torch.int64)
            gathered = [torch.empty_like(rank_value) for _ in range(world_size)]
            dist.all_gather(gathered, rank_value)
            ranks = sorted(int(value.item()) for value in gathered)
            if ranks != list(range(world_size)):
                raise SystemExit(f"llm_torch_smoke: non-unique ranks observed: {ranks}")

        torch.manual_seed(20260714)
        if want_cuda:
            torch.cuda.manual_seed_all(20260714)

        class TinyLanguageModel(nn.Module):
            def __init__(self) -> None:
                super().__init__()
                self.embedding = nn.Embedding(17, 8)
                self.projection = nn.Linear(8, 17)

            def forward(self, tokens: torch.Tensor) -> torch.Tensor:
                return self.projection(self.embedding(tokens))

        model = TinyLanguageModel().to(device)
        if any(parameter.device != device for parameter in model.parameters()):
            raise SystemExit("llm_torch_smoke: model parameter device mismatch")
        if world_size > 1:
            model = DistributedDataParallel(
                model,
                device_ids=[device.index] if want_cuda else None,
                output_device=device.index if want_cuda else None,
            )

        tokens = torch.tensor(
            [[1, 2, 3, 4], [4, 3, 2, 1]], dtype=torch.long, device=device
        )
        targets = torch.tensor(
            [[2, 3, 4, 5], [3, 2, 1, 0]], dtype=torch.long, device=device
        )
        optimizer = torch.optim.SGD(model.parameters(), lr=0.05)
        first_parameter = next(model.parameters())
        before = first_parameter.detach().clone()

        optimizer.zero_grad(set_to_none=True)
        logits = model(tokens)
        if logits.device != device or logits.shape != (2, 4, 17):
            raise SystemExit("llm_torch_smoke: logits shape or device mismatch")
        loss = functional.cross_entropy(logits.reshape(-1, 17), targets.reshape(-1))
        if not math.isfinite(float(loss.detach().cpu())):
            raise SystemExit("llm_torch_smoke: non-finite forward loss")
        loss.backward()

        gradients = [
            parameter.grad for parameter in model.parameters() if parameter.grad is not None
        ]
        if not gradients or not all(torch.isfinite(gradient).all() for gradient in gradients):
            raise SystemExit("llm_torch_smoke: missing or non-finite gradients")
        gradient_l1 = sum(float(gradient.detach().abs().sum().cpu()) for gradient in gradients)
        if not math.isfinite(gradient_l1) or gradient_l1 <= 0.0:
            raise SystemExit("llm_torch_smoke: zero or non-finite gradient norm")

        optimizer.step()
        parameter_delta = float((first_parameter.detach() - before).abs().max().cpu())
        if not math.isfinite(parameter_delta) or parameter_delta <= 0.0:
            raise SystemExit("llm_torch_smoke: optimizer did not update parameters")

        mean_loss = loss.detach().clone()
        if initialized:
            dist.all_reduce(mean_loss, op=dist.ReduceOp.SUM)
            mean_loss /= world_size
        if not torch.isfinite(mean_loss):
            raise SystemExit("llm_torch_smoke: reduced loss is non-finite")

        if rank == 0:
            print(
                "llm_torch=pass "
                f"torch={torch.__version__} device={device.type} "
                f"world_size={world_size} loss={float(mean_loss.cpu()):.6f} "
                f"gradient_l1={gradient_l1:.6f} "
                f"parameter_delta={parameter_delta:.6e}"
            )
    finally:
        if initialized and dist.is_initialized():
            dist.destroy_process_group()


if __name__ == "__main__":
    main()
