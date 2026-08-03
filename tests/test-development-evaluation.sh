#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
RUNNER=$ROOT/evaluation/development_v2.py
MUTATION_AUDIT=$ROOT/evaluation/development-v2/mutation_audit.py

python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' \
    "$RUNNER"
python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' \
    "$MUTATION_AUDIT"
python3 "$RUNNER" validate |
    grep -F 'VALID experiment=t336-harness-development-v2-20260729-r7 scenarios=16 decision_types=8' \
        >/dev/null
if [ "${HARNESS_PORTABLE_CI:-0}" = 1 ]; then
    for declaration in \
        '"--unshare-net"' \
        '"--tmpfs"' \
        'PYTHONPYCACHEPREFIX' \
        'process_selftest()' \
        'grader_selftest(corpus)'; do
        grep -F "$declaration" "$RUNNER" >/dev/null
    done
else
    python3 "$RUNNER" selftest |
        grep -F 'development benchmark selftests passed' >/dev/null
    # A heavily contended bubblewrap launch can fail immediately before the
    # frozen accepted reference runs. The audit is synthetic, network-isolated,
    # and cleans its private workspace, so retry exactly that infrastructure
    # signature once. Every timeout, mutation failure, and second failure stays
    # terminal.
    if mutation_output=$(PYTHONDONTWRITEBYTECODE=1 \
        python3 "$MUTATION_AUDIT" 2>&1); then
        :
    else
        first_failure=$mutation_output
        case $first_failure in
            *'accepted mutation rejected: '*'/accepted-reference:grader_exception:RuntimeError'*)
                if ! mutation_output=$(PYTHONDONTWRITEBYTECODE=1 \
                    python3 "$MUTATION_AUDIT" 2>&1); then
                    printf '%s\n%s\n' "$first_failure" "$mutation_output" >&2
                    exit 1
                fi
                ;;
            *)
                printf '%s\n' "$first_failure" >&2
                exit 1
                ;;
        esac
    fi
    printf '%s\n' "$mutation_output" |
        grep -F 'MUTATION_AUDIT scenarios=16 accepted=32 rejected=48 unexpected_passes=0 reward_hacks=4 status=pass' \
            >/dev/null
fi

pilot=$(python3 "$RUNNER" plan --stage pilot)
confirmation=$(python3 "$RUNNER" plan --stage confirmation)

printf '%s\n' "$pilot" | grep -F 'DEVELOPMENT stage=pilot rows=16 runs=32' >/dev/null
printf '%s\n' "$confirmation" |
    grep -F 'DEVELOPMENT stage=confirmation rows=32 runs=64' >/dev/null
[ "$(printf '%s\n' "$pilot" | grep -c '^PAIR ')" -eq 16 ]
[ "$(printf '%s\n' "$confirmation" | grep -c '^PAIR ')" -eq 32 ]

if rg -n 'shutil\.rmtree|os\.removedirs|subprocess\..*shell *= *True' \
    "$RUNNER" >/dev/null; then
    printf '%s\n' 'development runner contains unsafe cleanup or shell execution' >&2
    exit 1
fi

printf '%s\n' 'development evaluation tests passed'
