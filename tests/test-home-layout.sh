#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
awk -F'|' '
    /^#/ { next }
    NF != 7 { exit 1 }
    $1 !~ /^(local|ab|ab2|abq|al|rc|ri|t4)$/ { exit 1 }
    $2 !~ /^\// || $3 !~ /^\// { exit 1 }
    $4 == "" || $5 == "" || $6 == "" || $7 == "" { exit 1 }
    seen[$1]++ { exit 1 }
    { rows++ }
    END { if (rows != 8) exit 1 }
' "$ROOT/profiles/home-layout.tsv"

printf '%s\n' 'home layout declaration tests: PASS'
