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
    readme_count=$(grep -c "^| \`$logical\` |" "$README" || true)
    [ "$readme_count" -eq 0 ] || fail "duplicate README fleet row for $logical"
done

for guide in \
    'https://github.com/rioyokotalab/server-admin/wiki/How-to-use-hinadori-cluster' \
    'https://docs.abci.ai/v3/en/' \
    'https://g-quat-abciq.github.io/abciq-docs/ja/' \
    'https://docs.cscs.ch/alps/' \
    'https://portal.cloud.r-ccs.riken.jp/' \
    'https://docs.r-ccs.riken.jp/rikyu/en/' \
    'https://www.t4.cii.isct.ac.jp/docs/all/' \
    'https://www.noc.cii.isct.ac.jp/en/server-hosting-service/'
do
    grep -F "$guide" "$DOC" >/dev/null || fail "missing Linux user guide: $guide"
done

echo "Fleet inventory tests passed"
