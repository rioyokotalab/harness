#!/bin/bash
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'pytorch-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac
case ${HARNESS_EXPECTED_REV:-} in
    ''|*[!0-9a-f]*) printf '%s\n' 'pytorch-readiness: invalid expected revision' >&2; exit 2 ;;
esac
[ "${#HARNESS_EXPECTED_REV}" -eq 40 ] || exit 2

real_home=$HOME
root=$real_home/harness
state_root=$real_home/.local/state/harness/hpc-readiness
run_tag=${HARNESS_READINESS_RUN_TAG:-v1}
case $run_tag in ''|*[!A-Za-z0-9._-]*) exit 2 ;; esac
[ "${#run_tag}" -le 32 ] || exit 2
result=$state_root/t251-pytorch-$host-$run_tag.out
profile=$root/profiles/hosts/$host.conf
persistent_root=$(sed -n 's/^persistent_root=//p' "$profile")
[ -n "$persistent_root" ] || exit 2

case $host in
    ri|al|rc)
        expected_arch=aarch64
        manifest_sha=ed070849ba8da9fcf34e574a0f26e6adf510ffa7a8722201af4ecf7a64346988
        ;;
    *)
        expected_arch=x86_64
        manifest_sha=b5961b56df9301d3fc19234e5c6679ed186e5c49d1f5d1796a656fd3dcd626e6
        ;;
esac
artifact_name=pytorch-2.12.1-cu130-cp312-$expected_arch-wheelhouse
wheelhouse=$persistent_root/framework-artifacts/$artifact_name
lock=$root/profiles/pytorch-2.12.1-cu130.requirements.lock
scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'pytorch-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t251-pytorch-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t251-pytorch-$host-$run_tag.XXXXXX"); then
    unlink -- "$capture"
    exit 2
fi
chmod 700 "$build"

finish() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -n "$build" ] && [ -d "$build" ]; then
        HOME=$real_home "$root/tests/guarded-test-cleanup.sh" \
            "$real_home/.local/bin/harness" \
            "$scratch" "$build" "$scratch" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    if [ -n "$capture" ] && [ -f "$capture" ] && [ "$published" -eq 0 ]; then
        printf 'RESULT host=%s status=%s residue=%s\n' \
            "$host" "$status" "$cleanup_failed" >>"$capture"
        if ln -- "$capture" "$result"; then
            unlink -- "$capture"
            published=1
        else
            status=1
        fi
    fi
    exit "$status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
exec >"$capture" 2>&1
umask 077

"$root/tests/smoke/jobs/source-contract.sh" "$HARNESS_EXPECTED_REV" \
    profiles/pytorch-2.12.1-cu130.requirements.lock \
    profiles/pytorch-framework-routes.tsv \
    tests/smoke/llm_torch.py \
    tests/smoke/jobs/pytorch-readiness.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh \
    "profiles/hosts/$host.conf"

case $host in
    local|ri|al|rc) [ -n "${SLURM_JOB_ID:-}" ] ;;
    ab|ab2) [ -n "${PBS_JOBID:-}" ] ;;
    t4) [ -n "${JOB_ID:-}" ] ;;
esac
[ "$(uname -m)" = "$expected_arch" ]
python=
for candidate in \
    "$real_home/.local/bin/python3.12" \
    /usr/bin/python3.12 \
    /usr/local/bin/python3.12
do
    [ -x "$candidate" ] || continue
    metadata=$($candidate -c \
        'import platform, sys; print(f"{sys.version_info[0]}.{sys.version_info[1]} {platform.machine()}")' \
        2>/dev/null) || continue
    [ "$metadata" = "3.12 $expected_arch" ] || continue
    python=$candidate
    break
done
[ -n "$python" ] || {
    printf 'FAIL exact-python expected=3.12/%s\n' "$expected_arch"
    exit 2
}
printf 'GATE exact-python status=pass version=3.12 architecture=%s path=%s\n' \
    "$expected_arch" "$python"

[ -d "$wheelhouse" ] && [ ! -L "$wheelhouse" ]
[ "$(stat -c %a "$wheelhouse")" = 555 ]
[ "$(find "$wheelhouse" -maxdepth 1 -type f -name '*.whl' | wc -l)" -eq 29 ]
[ "$(find "$wheelhouse" -maxdepth 1 -type f -printf '%m\n' |
    awk '$0 != 444 {count++} END {print count+0}')" -eq 0 ]
[ "$(sha256sum "$wheelhouse/SHA256SUMS" | awk '{print $1}')" = "$manifest_sha" ]
[ "$(sha256sum "$lock" | awk '{print $1}')" = \
    07cc4a2e19ede271942d8050ef6f9e7349cefbf5b526b98bdc24dafde1401967 ]
grep -Fx "architecture=$expected_arch" "$wheelhouse/ARTIFACT" >/dev/null
grep -Fx 'torch=2.12.1+cu130' "$wheelhouse/ARTIFACT" >/dev/null
grep -Fx 'cuda=13.0' "$wheelhouse/ARTIFACT" >/dev/null
(
    cd "$wheelhouse"
    sha256sum -c SHA256SUMS
)
printf 'GATE artifact-lock status=pass architecture=%s wheels=29\n' "$expected_arch"

mkdir -m 700 "$build/home" "$build/cache" "$build/config" "$build/data" "$build/tmp"
export HOME=$build/home
export XDG_CACHE_HOME=$build/cache
export XDG_CONFIG_HOME=$build/config
export XDG_DATA_HOME=$build/data
export TMPDIR=$build/tmp
export PIP_CACHE_DIR=$build/cache/pip
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_INDEX=1
export PYTHONNOUSERSITE=1
export PYTHONDONTWRITEBYTECODE=1

printf '%s\n' 'NATIVE python3.12 -m venv BUILD/venv'
"$python" -m venv "$build/venv"
printf '%s\n' 'NATIVE BUILD/venv/bin/python -m pip install --no-index --no-cache-dir --find-links WHEELHOUSE --require-hashes -r LOCK'
"$build/venv/bin/python" -m pip install --no-index --no-cache-dir \
    --find-links "$wheelhouse" --require-hashes -r "$lock"

"$build/venv/bin/python" - <<'PY'
import math
import os
import torch

assert torch.__version__ == "2.12.1+cu130", torch.__version__
assert torch.version.cuda == "13.0", torch.version.cuda
print("GATE framework-version status=pass torch=2.12.1+cu130 cuda=13.0")

visible = os.environ.get("CUDA_VISIBLE_DEVICES", "")
assert not visible or "," not in visible, visible
assert torch.cuda.is_available()
assert torch.cuda.device_count() == 1, torch.cuda.device_count()
torch.cuda.set_device(0)
print("GATE scheduler-device status=pass count=1")

a = torch.tensor([1.0, 2.0, 3.0], device="cuda")
b = (a.square().sum() / 2.0).item()
assert math.isfinite(b) and b == 7.0, b
print("GATE finite-tensor status=pass")
PY

printf '%s\n' 'NATIVE BUILD/venv/bin/python tests/smoke/llm_torch.py --device cuda --require-world-size 1'
"$build/venv/bin/python" "$root/tests/smoke/llm_torch.py" \
    --device cuda --require-world-size 1
printf '%s\n' 'GATE tiny-lm status=pass'

[ "$HOME" = "$build/home" ]
[ "$XDG_CACHE_HOME" = "$build/cache" ]
[ "$PIP_CACHE_DIR" = "$build/cache/pip" ]
printf '%s\n' 'GATE cache-home-isolation status=pass cleanup=guarded-on-exit'
printf 'PASS host=%s gate=pytorch-single-device-v1 run=%s\n' "$host" "$run_tag"
