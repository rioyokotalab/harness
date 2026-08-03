#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -f "$TMP/tmux"; rmdir "$TMP" 2>/dev/null || true' EXIT HUP INT TERM

cat >"$TMP/tmux" <<'EOF'
#!/bin/sh
printf '%s\n' "${PRODUCER_ROLE_FIXTURE:?}"
EOF
chmod +x "$TMP/tmux"

export PATH="$TMP:$PATH"
export PRODUCER_ROLE_FIXTURE='harness|cowork|0|harness|codex'
"$ROOT/libexec/harness-producer-ledger" role-check --pane %0 >/dev/null

grep -F 'reversible owner-choice' "$ROOT/PRODUCER.md" >/dev/null || {
    echo 'producer queue omits reversible owner-choice parking' >&2
    exit 1
}
grep -F 'Never delete or rewrite a terminal receipt' \
    "$ROOT/PRODUCER.md" >/dev/null || {
    echo 'producer queue permits terminal receipt reuse' >&2
    exit 1
}

for fixture in \
    'projects|cowork|0|harness|codex' \
    'harness|codex|0|harness|codex' \
    'harness|cowork|1|harness|codex' \
    'harness|cowork|0|personal|codex' \
    'harness|cowork|0|harness|claude'; do
    export PRODUCER_ROLE_FIXTURE=$fixture
    if "$ROOT/libexec/harness-producer-ledger" role-check --pane %0 \
        >/dev/null 2>&1; then
        printf 'accepted invalid producer role: %s\n' "$fixture" >&2
        exit 1
    fi
done

python3 "$ROOT/tests/test_producer_ledger.py"
printf 'producer_role_tests=pass\n'
