#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
DOC=$ROOT/docs/fleet-inventory.md
README=$ROOT/README.md

fail() { echo "FAIL: $*" >&2; exit 1; }

[ -f "$DOC" ] && [ ! -L "$DOC" ] || fail "fleet inventory missing"
[ -f "$README" ] && [ ! -L "$README" ] || fail "README missing"
grep -F 'docs/fleet-inventory.md' "$ROOT/AGENTS.md" >/dev/null ||
    fail "cold-start inventory pointer missing"

for logical in local ab ab2 abq al rc ri t4 web aist home office riken; do
    count=$(grep -c "^| \`$logical\` |" "$DOC")
    [ "$count" -eq 1 ] || fail "fleet row count for $logical"
    readme_count=$(grep -c "^| \`$logical\` |" "$README")
    [ "$readme_count" -eq 1 ] || fail "README fleet row count for $logical"
    row=$(grep "^| \`$logical\` |" "$DOC")
    grep -F -x "$row" "$README" >/dev/null ||
        fail "README fleet row differs for $logical"
done

# shellcheck disable=SC2016
grep -F '| `web` | `web` (SFTP only) | `gsic0017` | `web-o3.noc.titech.ac.jp` | `sftp` | Rocky Linux 8, x86_64 |' \
    "$DOC" >/dev/null || fail "documented web service row"
# shellcheck disable=SC2016
grep -F '| `abq` | `abq`, `abq2` | `qai10412cx` | `qas.q.abci.ai` | `qes*` | Red Hat Enterprise Linux 9.4, x86_64 |' \
    "$DOC" >/dev/null || fail "ABQ route row"

echo "Fleet inventory tests passed"
