#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
AUDIT=$ROOT/tools/public-repo-audit.py
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/public-repo-audit-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$TEST_ROOT/repo
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.name test
git -C "$repo" config user.email test@example.invalid

# Assemble the hostile sentinel at runtime so the scanner test itself does not
# leave a token-shaped literal in the current source tree.
fake_value='ghp_''FAKEVALUEFORREDACTION1234567890'
printf 'safe=true\n' >"$repo/config.txt"
printf 'api_key=%s\n' "$fake_value" >"$repo/.env"
git -C "$repo" add config.txt .env
git -C "$repo" commit -qm fixture
git -C "$repo" rm -q .env
git -C "$repo" commit -qm remove-fixture

mkdir -p "$TEST_ROOT/out"
stdout=$TEST_ROOT/stdout
stderr=$TEST_ROOT/stderr
report=$TEST_ROOT/out/report.json
python3 "$AUDIT" --repo "$repo" --name fixture --output "$report" \
    >"$stdout" 2>"$stderr" || fail "fixture audit"

[ -f "$report" ] && [ ! -L "$report" ] || fail "report metadata"
[ "$(stat -c '%a' "$report")" = 644 ] || fail "report mode"
if grep -F "$fake_value" "$stdout" "$stderr" "$report" >/dev/null; then
    fail "matched value escaped redaction"
fi
python3 - "$report" <<'PY' || fail "report schema"
import json
import sys

report = json.load(open(sys.argv[1], encoding="utf-8"))
assert report["schema"] == 1
assert report["value_exposed"] is False
assert report["counts"]["commits"] == 2
assert report["finding_counts"]["suspicious-path"] >= 1
assert report["finding_counts"]["known-token-shape"] >= 1
assert report["finding_counts"]["credential-assignment"] >= 1
assert report["finding_counts"]["high-entropy-credential"] >= 1
assert report["counts"]["retained_findings"] == len(report["findings"])
for finding in report["findings"]:
    assert set(finding) == {
        "example_commit", "metadata_fingerprint", "object_id", "path", "rule_id", "size"
    }
PY

if python3 "$AUDIT" --repo "$repo" --name fixture --output "$report" \
    >"$TEST_ROOT/reuse.out" 2>&1; then
    fail "existing report was overwritten"
fi

printf '%s\n' 'public repository audit tests passed'
