#!/usr/bin/env python3
"""Synthetic repository-local productive-idle selector for Har-383.

This module is intentionally not exposed through ``harness``.  It operates only
on an explicitly supplied Git fixture root and models the frozen nightly
catalog, admission, selection, journal, receipt, and recovery contracts.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import tempfile
from typing import Iterable, Sequence


CATALOG_HEADER = ("opportunity_id", "packet")
CARD_FIELDS = (
    "opportunity_id",
    "lane",
    "priority",
    "expires_at",
    "authority",
    "conflict_key",
    "privacy",
    "predicate_key",
    "predicate_identity",
    "predicate_state",
    "p10_minutes",
    "p50_minutes",
    "p90_minutes",
    "matched_receipts",
    "validation_minutes",
    "publication_minutes",
    "independent_value",
    "target_path",
)
ADMISSION_HEADER = (
    "run_token",
    "catalog_oid",
    "until",
    "finalize_at",
    "admitted_at",
    "opportunity_id",
    "packet",
    "packet_blob",
    "predicate_identity",
)
EVENT_HEADER = (
    "sequence",
    "run_token",
    "opportunity_id",
    "state",
    "observed_at",
    "candidate_token",
    "detail",
)
RECEIPT_FIELDS = (
    "run_token",
    "opportunity_id",
    "disposition",
    "candidate_token",
    "target_identity",
    "observed_at",
)

ID_RE = re.compile(r"opp-[0-9a-f]{16}")
RUN_RE = re.compile(r"run-[0-9a-f]{16}")
DIGEST_RE = re.compile(r"[0-9a-f]{64}")
OID_RE = re.compile(r"(?:[0-9a-f]{40}|[0-9a-f]{64})")
KEY_RE = re.compile(r"[a-z0-9][a-z0-9._-]{0,63}")
ALLOWED_AUTHORITY = {"read-only", "repository-local", "protected-publication"}
ALLOWED_DISPOSITIONS = {"complete", "no-change", "blocked", "skipped", "interrupted"}
SENSITIVE_TERMS = {"credential", "secret", "password", "prompt", "response", "email", "calendar", "budget"}
MAX_CARD_BYTES = 4096
MAX_SELECTOR_BYTES = 1024
MAX_CARDS = 12


class Rejected(ValueError):
    """A value-free contract rejection."""


def reject(reason: str) -> None:
    if not KEY_RE.fullmatch(reason):
        raise RuntimeError("unsafe rejection reason")
    raise Rejected(reason)


def parse_time(raw: str) -> datetime:
    try:
        value = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        reject("invalid-time")
    if value.tzinfo is None:
        reject("timezone-required")
    return value.astimezone(timezone.utc)


def format_time(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def atomic_write(path: Path, value: bytes) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    parent = path.parent
    if parent.is_symlink():
        reject("unsafe-parent")
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=parent)
    temporary_path = Path(temporary)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb", closefd=True) as stream:
            stream.write(value)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary_path, path)
        directory = os.open(parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def encode_tsv(header: Sequence[str], rows: Iterable[Sequence[str]]) -> bytes:
    lines = ["\t".join(header)]
    for row in rows:
        fields = list(row)
        if len(fields) != len(header) or any("\t" in field or "\n" in field for field in fields):
            reject("invalid-tsv-value")
        lines.append("\t".join(fields))
    return ("\n".join(lines) + "\n").encode()


def parse_tsv(value: bytes, header: Sequence[str]) -> list[dict[str, str]]:
    try:
        text = value.decode("utf-8")
    except UnicodeDecodeError:
        reject("invalid-encoding")
    if not text.endswith("\n") or "\r" in text:
        reject("invalid-tsv-framing")
    rows = list(csv.reader(text.splitlines(), delimiter="\t", strict=True))
    if not rows or tuple(rows[0]) != tuple(header):
        reject("invalid-tsv-schema")
    if any(len(row) != len(header) for row in rows[1:]):
        reject("invalid-tsv-row")
    return [dict(zip(header, row, strict=True)) for row in rows[1:]]


def parse_metadata(value: bytes, fields: Sequence[str]) -> dict[str, str]:
    try:
        text = value.decode("utf-8")
    except UnicodeDecodeError:
        reject("invalid-encoding")
    if not text.endswith("\n") or "\r" in text:
        reject("invalid-metadata-framing")
    result: dict[str, str] = {}
    for line in text.splitlines():
        if line.count(": ") != 1:
            reject("invalid-metadata-row")
        key, item = line.split(": ", 1)
        if key in result:
            reject("duplicate-metadata-key")
        result[key] = item
    if tuple(result) != tuple(fields):
        reject("invalid-metadata-schema")
    return result


def encode_metadata(fields: Sequence[str], values: dict[str, str]) -> bytes:
    if tuple(values) != tuple(fields):
        reject("invalid-metadata-schema")
    if any("\n" in value or "\r" in value for value in values.values()):
        reject("invalid-metadata-value")
    return "".join(f"{field}: {values[field]}\n" for field in fields).encode()


@dataclass(frozen=True)
class Card:
    opportunity_id: str
    packet: str
    lane: str
    priority: int
    expires_at: datetime
    authority: str
    conflict_key: str
    privacy: str
    predicate_key: str
    predicate_identity: str
    predicate_state: str
    p10_minutes: float | None
    p50_minutes: float
    p90_minutes: float
    matched_receipts: int
    validation_minutes: float
    publication_minutes: float
    target_path: str

    @property
    def total_p90(self) -> float:
        return self.p90_minutes + self.validation_minutes + self.publication_minutes


class PilotRepository:
    def __init__(self, root: Path):
        self.root = root.absolute()
        if not self.root.is_dir() or self.root.is_symlink() or not (self.root / ".git").exists():
            reject("invalid-fixture-root")
        self._freshness_cache: dict[tuple[str, str], tuple[int, int, int, bool]] = {}

    def git(self, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            stdin=subprocess.DEVNULL,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"},
        )
        if check and result.returncode != 0:
            reject("git-state-unavailable")
        return result

    def relative(self, raw: str) -> Path:
        candidate = PurePosixPath(raw)
        if not raw or candidate.is_absolute() or ".." in candidate.parts or "." in candidate.parts:
            reject("unsafe-relative-path")
        path = self.root.joinpath(*candidate.parts)
        current = self.root
        for part in candidate.parts[:-1]:
            current = current / part
            if current.exists() and current.is_symlink():
                reject("unsafe-path-component")
        return path

    def read_regular(self, raw: str, maximum: int) -> bytes:
        path = self.relative(raw)
        try:
            info = path.lstat()
        except FileNotFoundError:
            reject("required-file-absent")
        if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o111 or info.st_size > maximum:
            reject("unsafe-file")
        return path.read_bytes()

    def relative_name(self, path: Path) -> str:
        try:
            return path.relative_to(self.root).as_posix()
        except ValueError:
            reject("path-outside-root")

    def require_clean(self, paths: Sequence[str]) -> None:
        result = self.git("status", "--porcelain=v1", "--untracked-files=all", "--", *paths)
        if result.stdout:
            reject("dirty-frozen-input")

    def head_oid(self) -> str:
        value = self.git("rev-parse", "HEAD").stdout.strip()
        if not OID_RE.fullmatch(value):
            reject("invalid-head")
        return value

    def blob_oid(self, revision: str, path: str) -> str:
        value = self.git("rev-parse", f"{revision}:{path}").stdout.strip()
        if not OID_RE.fullmatch(value):
            reject("missing-protected-blob")
        return value

    def show_blob(self, revision: str, path: str) -> bytes:
        result = subprocess.run(
            ["git", "show", f"{revision}:{path}"],
            cwd=self.root,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"},
        )
        if result.returncode != 0:
            reject("missing-protected-blob")
        return result.stdout

    def load_catalog(self) -> list[Card]:
        index_path = "docs/producer/nightly/index.tsv"
        rows = parse_tsv(self.read_regular(index_path, 16384), CATALOG_HEADER)
        if len(rows) > MAX_CARDS:
            reject("catalog-cap-exceeded")
        cards: list[Card] = []
        seen: set[str] = set()
        for row in rows:
            opportunity_id = row["opportunity_id"]
            expected = f"docs/producer/nightly/cards/{opportunity_id}.md"
            if not ID_RE.fullmatch(opportunity_id) or opportunity_id in seen or row["packet"] != expected:
                reject("invalid-catalog-identity")
            seen.add(opportunity_id)
            value = self.read_regular(expected, MAX_CARD_BYTES)
            raw = parse_metadata(value, CARD_FIELDS)
            if raw["opportunity_id"] != opportunity_id:
                reject("card-identity-mismatch")
            if raw["lane"] not in {"mandatory", "reserve"}:
                reject("invalid-lane")
            if raw["authority"] not in ALLOWED_AUTHORITY:
                reject("invalid-authority")
            if raw["privacy"] not in {"public", "private"}:
                reject("invalid-privacy")
            if raw["predicate_state"] not in {"ready", "blocked", "stale"}:
                reject("invalid-predicate-state")
            if raw["independent_value"] != "true":
                reject("make-work-card")
            if not KEY_RE.fullmatch(raw["conflict_key"]) or not KEY_RE.fullmatch(raw["predicate_key"]):
                reject("invalid-card-key")
            if not DIGEST_RE.fullmatch(raw["predicate_identity"]):
                reject("invalid-predicate-identity")
            if raw["privacy"] == "public":
                lowered = " ".join(raw.values()).lower()
                if any(term in lowered for term in SENSITIVE_TERMS) or "private-canary" in lowered:
                    reject("public-privacy-canary")
            self.relative(raw["target_path"])
            try:
                priority = int(raw["priority"])
                matched = int(raw["matched_receipts"])
                p10 = None if raw["p10_minutes"] == "unknown" else float(raw["p10_minutes"])
                p50 = float(raw["p50_minutes"])
                p90 = float(raw["p90_minutes"])
                validation = float(raw["validation_minutes"])
                publication = float(raw["publication_minutes"])
            except ValueError:
                reject("invalid-card-number")
            numbers = [p50, p90, validation, publication, *([] if p10 is None else [p10])]
            if not 0 <= priority <= 999 or matched < 0 or any(not math.isfinite(item) or item < 0 for item in numbers):
                reject("invalid-card-number")
            if matched < 20 and p90 < 2 * p50:
                reject("unsupported-p90")
            if matched < 20 and p10 is not None:
                reject("unsupported-p10")
            if p50 > p90 or (p10 is not None and p10 > p50):
                reject("invalid-timing-order")
            cards.append(
                Card(
                    opportunity_id,
                    expected,
                    raw["lane"],
                    priority,
                    parse_time(raw["expires_at"]),
                    raw["authority"],
                    raw["conflict_key"],
                    raw["privacy"],
                    raw["predicate_key"],
                    raw["predicate_identity"],
                    raw["predicate_state"],
                    p10,
                    p50,
                    p90,
                    matched,
                    validation,
                    publication,
                    raw["target_path"],
                )
            )
        return cards

    def target_ready(self, card: Card) -> bool:
        if card.predicate_state != "ready":
            return False
        try:
            target = self.relative(card.target_path)
            info = target.lstat()
            if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o111 or info.st_size > 1024 * 1024:
                return False
            cache_key = (card.target_path, card.predicate_identity)
            event_key = (info.st_ino, info.st_size, info.st_mtime_ns)
            cached = self._freshness_cache.get(cache_key)
            if cached is not None and cached[:3] == event_key:
                return cached[3]
            value = target.read_bytes()
        except (FileNotFoundError, Rejected):
            return False
        result = digest_bytes(value) == card.predicate_identity
        self._freshness_cache[cache_key] = (*event_key, result)
        return result

    @staticmethod
    def finalize_at(now: datetime, until: datetime) -> datetime:
        window = (until - now).total_seconds() / 60
        if window <= 0:
            reject("expired-window")
        reserve = max(60.0, window * 0.15)
        return until - timedelta(minutes=reserve)

    def eligible(
        self,
        cards: Sequence[Card],
        now: datetime,
        finalize_at: datetime,
        held_conflicts: set[str] | None = None,
    ) -> list[Card]:
        held = held_conflicts or set()
        remaining = (finalize_at - now).total_seconds() / 60
        result = [
            card
            for card in cards
            if card.expires_at > now
            and card.conflict_key not in held
            and card.total_p90 <= remaining
            and self.target_ready(card)
        ]
        return sorted(result, key=lambda card: (0 if card.lane == "mandatory" else 1, card.priority, card.expires_at, card.opportunity_id))

    def plan(
        self,
        now: datetime,
        until: datetime,
        *,
        discovery_used: bool = False,
        held_conflicts: set[str] | None = None,
    ) -> dict[str, object]:
        cards = self.load_catalog()
        finalize = self.finalize_at(now, until)
        eligible = self.eligible(cards, now, finalize, held_conflicts)
        usable = max(0.0, (finalize - now).total_seconds() / 60)
        p10_known = [card.p10_minutes for card in eligible if card.p10_minutes is not None]
        p50 = sum(card.p50_minutes for card in eligible)
        p90 = sum(card.p90_minutes for card in eligible)
        lower = sum(p10_known)
        state = "covered" if p50 >= usable else ("planned-wait" if discovery_used else "shortfall")
        return {
            "status": state,
            "requested_until": format_time(until),
            "finalize_at": format_time(finalize),
            "eligible_cards": len(eligible),
            "p10_minutes": lower,
            "p10_unknown_cards": len(eligible) - len(p10_known),
            "p50_minutes": p50,
            "p90_minutes": p90,
            "usable_minutes": usable,
        }

    def admission_path(self, run_token: str) -> str:
        if not RUN_RE.fullmatch(run_token):
            reject("invalid-run-token")
        return f"docs/audits/{run_token}/admissions.tsv"

    def events_path(self, run_token: str) -> str:
        if not RUN_RE.fullmatch(run_token):
            reject("invalid-run-token")
        return f"docs/audits/{run_token}/events.tsv"

    def receipt_path(self, run_token: str, opportunity_id: str) -> str:
        if not RUN_RE.fullmatch(run_token) or not ID_RE.fullmatch(opportunity_id):
            reject("invalid-receipt-identity")
        return f"docs/consumer/nightly-receipts/{run_token}/{opportunity_id}.md"

    def admit(self, run_token: str, now: datetime, until: datetime) -> dict[str, object]:
        path = self.admission_path(run_token)
        if self.relative(path).exists():
            reject("admission-exists")
        catalog_paths = ["docs/producer/nightly/index.tsv"]
        cards = self.load_catalog()
        catalog_paths.extend(card.packet for card in cards)
        self.require_clean(catalog_paths)
        head = self.head_oid()
        finalize = self.finalize_at(now, until)
        selected = self.eligible(cards, now, finalize)[:MAX_CARDS]
        rows = [
            (
                run_token,
                head,
                format_time(until),
                format_time(finalize),
                format_time(now),
                "-",
                "-",
                "-",
                "-",
            )
        ] + [
            (
                run_token,
                head,
                format_time(until),
                format_time(finalize),
                format_time(now),
                card.opportunity_id,
                card.packet,
                self.blob_oid(head, card.packet),
                card.predicate_identity,
            )
            for card in selected
        ]
        atomic_write(self.relative(path), encode_tsv(ADMISSION_HEADER, rows))
        return {"status": "admitted", "cards": len(selected), "catalog_oid": head}

    def _first_add_blob(self, path: str) -> bytes:
        commits = self.git("log", "--reverse", "--diff-filter=A", "--format=%H", "--", path).stdout.splitlines()
        if len(commits) != 1:
            reject("immutable-first-add-missing")
        return self.show_blob(commits[0], path)

    def load_admission(self, run_token: str) -> list[dict[str, str]]:
        path = self.admission_path(run_token)
        self.require_clean([path])
        value = self.read_regular(path, 65536)
        if self._first_add_blob(path) != value:
            reject("admission-rewritten")
        rows = parse_tsv(value, ADMISSION_HEADER)
        selected_paths = [row["packet"] for row in rows if row["opportunity_id"] != "-"]
        self.require_clean(["docs/producer/nightly/index.tsv", *selected_paths])
        seen: set[str] = set()
        common: tuple[str, str, str, str, str] | None = None
        for number, row in enumerate(rows):
            current = (row["run_token"], row["catalog_oid"], row["until"], row["finalize_at"], row["admitted_at"])
            if common is None:
                common = current
            if current != common or row["run_token"] != run_token:
                reject("inconsistent-admission")
            if not OID_RE.fullmatch(row["catalog_oid"]):
                reject("invalid-admission-identity")
            parse_time(row["until"])
            parse_time(row["finalize_at"])
            parse_time(row["admitted_at"])
            if self.git("merge-base", "--is-ancestor", row["catalog_oid"], "HEAD", check=False).returncode != 0:
                reject("catalog-history-diverged")
            if number == 0 and row["opportunity_id"] == "-":
                if any(row[field] != "-" for field in ("packet", "packet_blob", "predicate_identity")):
                    reject("invalid-admission-control")
                continue
            if not ID_RE.fullmatch(row["opportunity_id"]) or row["opportunity_id"] in seen:
                reject("duplicate-admission")
            seen.add(row["opportunity_id"])
            if not OID_RE.fullmatch(row["packet_blob"]):
                reject("invalid-admission-identity")
            if row["packet"] != f"docs/producer/nightly/cards/{row['opportunity_id']}.md":
                reject("invalid-admission-packet")
            if self.blob_oid(row["catalog_oid"], row["packet"]) != row["packet_blob"]:
                reject("frozen-packet-mismatch")
            if self.blob_oid("HEAD", row["packet"]) != row["packet_blob"]:
                reject("current-packet-mismatch")
        if not rows or rows[0]["opportunity_id"] != "-":
            reject("admission-control-absent")
        return rows

    def _event_rows(self, run_token: str, *, require_clean: bool = True) -> list[dict[str, str]]:
        path = self.events_path(run_token)
        target = self.relative(path)
        if not target.exists():
            return []
        if require_clean:
            self.require_clean([path])
        value = self.read_regular(path, 262144)
        rows = parse_tsv(value, EVENT_HEADER)
        for number, row in enumerate(rows, 1):
            if row["sequence"] != str(number) or row["run_token"] != run_token:
                reject("event-sequence-invalid")
            if row["state"] not in {"discovery", "selected", "wait", "finalizing"}:
                reject("event-state-invalid")
            if row["opportunity_id"] != "-" and not ID_RE.fullmatch(row["opportunity_id"]):
                reject("event-identity-invalid")
            parse_time(row["observed_at"])
        if require_clean:
            self.verify_event_history(run_token, value)
        return rows

    def verify_event_history(self, run_token: str, current: bytes | None = None) -> None:
        path = self.events_path(run_token)
        commits = self.git("log", "--reverse", "--format=%H", "--", path).stdout.splitlines()
        if not commits:
            reject("event-checkpoint-missing")
        previous = encode_tsv(EVENT_HEADER, [])
        for commit in commits:
            value = self.show_blob(commit, path)
            if not value.startswith(previous):
                reject("event-prefix-rewritten")
            suffix = value[len(previous):]
            if suffix.count(b"\n") != 1 or not suffix.endswith(b"\n"):
                reject("event-append-not-atomic")
            parse_tsv(value, EVENT_HEADER)
            previous = value
        if current is not None and previous != current:
            reject("event-head-mismatch")

    def _append_event(
        self,
        run_token: str,
        opportunity_id: str,
        state: str,
        observed_at: datetime,
        candidate_token: str,
        detail: str,
    ) -> None:
        path = self.events_path(run_token)
        target = self.relative(path)
        rows = self._event_rows(run_token) if target.exists() else []
        row = (
            str(len(rows) + 1),
            run_token,
            opportunity_id,
            state,
            format_time(observed_at),
            candidate_token,
            detail,
        )
        old = encode_tsv(EVENT_HEADER, ([tuple(item[field] for field in EVENT_HEADER) for item in rows]))
        atomic_write(target, old + encode_tsv(EVENT_HEADER, [row]).split(b"\n", 1)[1])

    def _receipts(self, run_token: str, admissions: Sequence[dict[str, str]]) -> dict[str, dict[str, str]]:
        result: dict[str, dict[str, str]] = {}
        for row in admissions:
            opportunity_id = row["opportunity_id"]
            if opportunity_id == "-":
                continue
            path = self.receipt_path(run_token, opportunity_id)
            target = self.relative(path)
            if not target.exists():
                continue
            self.require_clean([path])
            value = self.read_regular(path, 4096)
            if self._first_add_blob(path) != value:
                reject("receipt-rewritten")
            values = parse_metadata(value, RECEIPT_FIELDS)
            if values["run_token"] != run_token or values["opportunity_id"] != opportunity_id:
                reject("receipt-identity-mismatch")
            if values["disposition"] not in ALLOWED_DISPOSITIONS or not DIGEST_RE.fullmatch(values["target_identity"]):
                reject("receipt-value-invalid")
            parse_time(values["observed_at"])
            result[opportunity_id] = values
        return result

    def _admitted_cards(self, admissions: Sequence[dict[str, str]]) -> list[Card]:
        by_id = {card.opportunity_id: card for card in self.load_catalog()}
        result: list[Card] = []
        for row in admissions:
            if row["opportunity_id"] == "-":
                continue
            card = by_id.get(row["opportunity_id"])
            if card is None or card.packet != row["packet"] or card.predicate_identity != row["predicate_identity"]:
                reject("admitted-card-drift")
            result.append(card)
        return result

    @staticmethod
    def candidate_token(run_token: str, row: dict[str, str]) -> str:
        return digest_bytes(f"{run_token}\0{row['opportunity_id']}\0{row['packet_blob']}".encode())

    def next_candidate(
        self,
        run_token: str,
        now: datetime,
        *,
        discovery_used: bool,
        held_conflicts: set[str] | None = None,
    ) -> dict[str, object]:
        admissions = self.load_admission(run_token)
        if not admissions:
            reject("admission-control-absent")
        receipts = self._receipts(run_token, admissions)
        events = self._event_rows(run_token)
        if any(event["state"] == "finalizing" for event in events):
            return {"status": "finalize", "reason": "one-way"}
        for event in events:
            if event["state"] == "selected" and event["opportunity_id"] not in receipts:
                return {
                    "status": "recover",
                    "candidate": event["candidate_token"],
                    "opportunity_id": event["opportunity_id"],
                }
        finalize = parse_time(admissions[0]["finalize_at"])
        if now >= finalize:
            return {"status": "finalize", "reason": "cutoff"}
        cards = self._admitted_cards(admissions)
        completed_predicates = {
            (card.predicate_key, card.predicate_identity)
            for card in cards
            if card.opportunity_id in receipts and receipts[card.opportunity_id]["disposition"] == "no-change"
        }
        eligible = [
            card
            for card in self.eligible(cards, now, finalize, held_conflicts)
            if card.opportunity_id not in receipts
            and (card.predicate_key, card.predicate_identity) not in completed_predicates
        ]
        if eligible:
            card = eligible[0]
            row = next(item for item in admissions if item["opportunity_id"] == card.opportunity_id)
            return {
                "status": "ready",
                "candidate": self.candidate_token(run_token, row),
                "opportunity_id": card.opportunity_id,
                "packet": card.packet,
            }
        if not discovery_used and not any(event["state"] == "discovery" for event in events):
            return {"status": "discovery", "scope": "delta-routed"}
        wait_token = digest_bytes(f"{run_token}\0{format_time(now)}\0{format_time(finalize)}".encode())
        return {
            "status": "wait",
            "wake_at": format_time(min(now + timedelta(hours=1), finalize)),
            "wake_on": "changed-input",
            "finalize_at": format_time(finalize),
            "checkpoint": self.head_oid(),
            "token": wait_token,
        }

    def start(self, run_token: str, expected_candidate: str, now: datetime, *, discovery_used: bool) -> dict[str, str]:
        selected = self.next_candidate(run_token, now, discovery_used=discovery_used)
        if selected["status"] != "ready" or selected["candidate"] != expected_candidate:
            reject("candidate-changed")
        opportunity_id = str(selected["opportunity_id"])
        if any(row["opportunity_id"] == opportunity_id for row in self._event_rows(run_token)):
            reject("duplicate-selection")
        self._append_event(run_token, opportunity_id, "selected", now, expected_candidate, "checkpoint-required")
        result = {"status": "selected", "candidate": expected_candidate, "packet": str(selected["packet"])}
        if len(json.dumps(result, separators=(",", ":")).encode()) > MAX_SELECTOR_BYTES:
            reject("selector-route-oversized")
        return result

    def checkpoint_wait(self, run_token: str, now: datetime, *, discovery_used: bool) -> dict[str, str]:
        self.require_clean(["."])
        selected = self.next_candidate(run_token, now, discovery_used=discovery_used)
        if selected["status"] not in {"wait", "finalize"}:
            reject("wait-not-eligible")
        events = self._event_rows(run_token)
        if any(row["state"] == "wait" for row in events):
            reject("duplicate-wait")
        if selected["status"] == "finalize":
            token = digest_bytes(f"{run_token}\0finalize".encode())
            self._append_event(run_token, "-", "finalizing", now, token, "one-way")
            return {"status": "finalizing", "token": token}
        token = str(selected["token"])
        detail = f"wake_at={selected['wake_at']};wake_on=changed-input;finalize_at={selected['finalize_at']};checkpoint={selected['checkpoint']}"
        self._append_event(run_token, "-", "wait", now, token, detail)
        return {"status": "wait", "token": token}

    def checkpoint_discovery(self, run_token: str, now: datetime) -> dict[str, str]:
        self.require_clean(["."])
        selected = self.next_candidate(run_token, now, discovery_used=False)
        if selected["status"] != "discovery":
            reject("discovery-not-eligible")
        token = digest_bytes(f"{run_token}\0discovery\0{format_time(now)}".encode())
        self._append_event(run_token, "-", "discovery", now, token, "delta-routed")
        return {"status": "discovery", "token": token}

    def receive(
        self,
        run_token: str,
        opportunity_id: str,
        disposition: str,
        candidate_token: str,
        target_identity: str,
        observed_at: datetime,
    ) -> dict[str, str]:
        if disposition not in ALLOWED_DISPOSITIONS or not DIGEST_RE.fullmatch(target_identity):
            reject("invalid-receipt-value")
        self.load_admission(run_token)
        events = self._event_rows(run_token)
        selections = [row for row in events if row["state"] == "selected" and row["opportunity_id"] == opportunity_id]
        if len(selections) != 1 or selections[0]["candidate_token"] != candidate_token:
            reject("selection-not-checkpointed")
        values = {
            "run_token": run_token,
            "opportunity_id": opportunity_id,
            "disposition": disposition,
            "candidate_token": candidate_token,
            "target_identity": target_identity,
            "observed_at": format_time(observed_at),
        }
        value = encode_metadata(RECEIPT_FIELDS, values)
        path = self.relative(self.receipt_path(run_token, opportunity_id))
        if path.exists():
            if self.read_regular(self.relative_name(path), 4096) == value:
                return {"status": "unchanged", "disposition": disposition}
            reject("changed-duplicate-receipt")
        atomic_write(path, value)
        return {"status": "received", "disposition": disposition}

    def public_status(self, run_token: str, now: datetime, *, discovery_used: bool) -> dict[str, str]:
        selected = self.next_candidate(run_token, now, discovery_used=discovery_used)
        status = str(selected["status"])
        return {"status": "ready" if status == "ready" else ("block" if status == "recover" else "idle")}


def rotate_repository(statuses: Sequence[str], cursor: int) -> int | None:
    if len(statuses) > 5:
        reject("portfolio-cap-exceeded")
    if any(status not in {"ready", "idle", "block"} for status in statuses):
        reject("cross-repository-value-exposure")
    if not statuses:
        return None
    for offset in range(1, len(statuses) + 1):
        index = (cursor + offset) % len(statuses)
        if statuses[index] == "ready":
            return index
    return None


def authority_decision(required: str, granted: set[str]) -> str:
    if required not in ALLOWED_AUTHORITY:
        return "skipped-blocked-receipt"
    return "eligible" if required in granted else "skipped-blocked-receipt"


def overrun_action(elapsed_minutes: float, expected_minutes: float) -> str:
    if not math.isfinite(elapsed_minutes) or not math.isfinite(expected_minutes) or expected_minutes <= 0:
        reject("invalid-overrun-input")
    return "checkpoint-readmit" if elapsed_minutes > 1.5 * expected_minutes else "continue"


def wake_decision(
    *,
    now: datetime,
    finalize_at: datetime,
    supplied_token: str,
    recorded_token: str,
    changed_input: bool,
    owner_amendment: bool,
) -> str:
    if supplied_token != recorded_token or not DIGEST_RE.fullmatch(recorded_token):
        return "no-op"
    if now >= finalize_at:
        return "finalize"
    if owner_amendment:
        return "amend-and-reselect"
    return "reselect" if changed_input else "wait"


def discovery_scope(
    *,
    promotion_slot: str | None,
    changed_receipts: Sequence[str],
    linked_evidence: str | None,
) -> tuple[str, ...]:
    values = [item for item in [promotion_slot, *changed_receipts, linked_evidence] if item]
    if len(values) > len(changed_receipts) + 2:
        reject("discovery-scope-invalid")
    for value in values:
        path = PurePosixPath(value)
        if path.is_absolute() or ".." in path.parts or any(part in {".git", "tmp", "branches", "web"} for part in path.parts):
            reject("broad-discovery-forbidden")
    if linked_evidence and len([item for item in values if item == linked_evidence]) != 1:
        reject("linked-evidence-limit")
    return tuple(values)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="productive-idle-pilot")
    parser.add_argument("--root", required=True)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("validate-catalog")
    plan = subparsers.add_parser("nightly-plan")
    plan.add_argument("--now", required=True)
    plan.add_argument("--until", required=True)
    plan.add_argument("--discovery-used", action="store_true")
    admit = subparsers.add_parser("nightly-admit")
    admit.add_argument("--run", required=True)
    admit.add_argument("--now", required=True)
    admit.add_argument("--until", required=True)
    next_parser = subparsers.add_parser("nightly-next")
    next_parser.add_argument("--run", required=True)
    next_parser.add_argument("--now", required=True)
    next_parser.add_argument("--discovery-used", action="store_true")
    start = subparsers.add_parser("nightly-start")
    start.add_argument("--run", required=True)
    start.add_argument("--now", required=True)
    start.add_argument("--expected-candidate", required=True)
    start.add_argument("--discovery-used", action="store_true")
    receive = subparsers.add_parser("nightly-receive")
    receive.add_argument("--run", required=True)
    receive.add_argument("--opportunity", required=True)
    receive.add_argument("--disposition", required=True)
    receive.add_argument("--candidate", required=True)
    receive.add_argument("--target-identity", required=True)
    receive.add_argument("--observed-at", required=True)
    wait = subparsers.add_parser("nightly-wait")
    wait.add_argument("--run", required=True)
    wait.add_argument("--now", required=True)
    wait.add_argument("--discovery-used", action="store_true")
    discovery = subparsers.add_parser("nightly-discovery")
    discovery.add_argument("--run", required=True)
    discovery.add_argument("--now", required=True)
    return parser.parse_args()


def main() -> int:
    arguments = parse_args()
    try:
        repository = PilotRepository(Path(arguments.root))
        if arguments.command == "validate-catalog":
            result: object = {"status": "pass", "cards": len(repository.load_catalog())}
        elif arguments.command == "nightly-plan":
            result = repository.plan(parse_time(arguments.now), parse_time(arguments.until), discovery_used=arguments.discovery_used)
        elif arguments.command == "nightly-admit":
            result = repository.admit(arguments.run, parse_time(arguments.now), parse_time(arguments.until))
        elif arguments.command == "nightly-next":
            result = repository.next_candidate(arguments.run, parse_time(arguments.now), discovery_used=arguments.discovery_used)
        elif arguments.command == "nightly-start":
            result = repository.start(arguments.run, arguments.expected_candidate, parse_time(arguments.now), discovery_used=arguments.discovery_used)
        elif arguments.command == "nightly-receive":
            result = repository.receive(arguments.run, arguments.opportunity, arguments.disposition, arguments.candidate, arguments.target_identity, parse_time(arguments.observed_at))
        elif arguments.command == "nightly-wait":
            result = repository.checkpoint_wait(arguments.run, parse_time(arguments.now), discovery_used=arguments.discovery_used)
        elif arguments.command == "nightly-discovery":
            result = repository.checkpoint_discovery(arguments.run, parse_time(arguments.now))
        else:
            raise RuntimeError("unhandled command")
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
        return 0
    except Rejected as error:
        print(json.dumps({"status": "rejected", "reason": str(error)}, sort_keys=True, separators=(",", ":")))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
