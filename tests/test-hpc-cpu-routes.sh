#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
MAP=$ROOT/profiles/hpc-cpu-routes.tsv
DOC=$ROOT/docs/bounded-cpu-routes.md

rows=$(awk -F'|' '
    /^#/ { next }
    NF != 10 { exit 2 }
    $0 ~ /[[:space:]]/ { exit 2 }
    $1 !~ /^(local|ab|ab2|ri|al|rc|t4)$/ { exit 2 }
    $2 !~ /^(ybatch|pbspro|slurm|age)$/ { exit 2 }
    $9 != "00:05:00" { exit 2 }
    seen[$1]++ { exit 2 }
    { count++ }
    END { if (count != 7) exit 2; print count }
' "$MAP") || { echo 'FAIL: bounded CPU route schema' >&2; exit 1; }
[ "$rows" -eq 7 ]

grep -Fx 'local|ybatch|none|none|none|none|ybatch:thrp_1|base|00:05:00|local-resource-directive' "$MAP" >/dev/null
grep -Fx 'ab|pbspro|-P|gag51395|-q|rt_HC|pbs:select=1|module:gcc/15.2.0|00:05:00|full-node-cpu' "$MAP" >/dev/null
grep -Fx 'ab2|pbspro|-P|gah51624|-q|rt_HC|pbs:select=1|module:gcc/15.2.0|00:05:00|full-node-cpu' "$MAP" >/dev/null
grep -Fx 'ri|slurm|--account|rkp00015|--partition|gpu|slurm:nodes=1,ntasks=1,cpus-per-task=1,gres=none|base|00:05:00|site-injects-gpu' "$MAP" >/dev/null
grep -Fx 'al|slurm|--account|g177-1|--partition|normal|slurm:nodes=1,ntasks=1,cpus-per-task=1|uenv:prgenv-gnu/25.11:v1,view=default|00:05:00|native-uenv' "$MAP" >/dev/null
grep -Fx 'rc|slurm|--account|cloud-users|--partition|r340|slurm:nodes=1,ntasks=1,cpus-per-task=1,gres=none|base|00:05:00|x86-cpu-route' "$MAP" >/dev/null
grep -Fx 't4|age|-g|jh250019|none|none|age:cpu_4=1|module:gcc/14.2.0|00:05:00|native-group-flag' "$MAP" >/dev/null

grep -F 'not authority for a project job' "$DOC" >/dev/null
grep -F 'wrapper zero alone is insufficient' "$DOC" >/dev/null
grep -F '`-g` selects the group; `-A` does not' "$DOC" >/dev/null
printf '%s\n' 'bounded CPU route tests: PASS'
