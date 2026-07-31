#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SCENARIOS=$ROOT/docs/audits/t351-autonomy-efficiency/context-scenarios.tsv

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
words() { wc -w <"$1" | tr -d ' '; }

[ -f "$SCENARIOS" ] && [ ! -L "$SCENARIOS" ] ||
    fail 'missing context scenario manifest'

todo_lines=$(wc -l <"$ROOT/TODO.md" | tr -d ' ')
todo_words=$(words "$ROOT/TODO.md")
[ "$todo_lines" -le 250 ] ||
    fail "active board line budget exceeded: $todo_lines"
[ "$todo_words" -le 2500 ] ||
    fail "active board word budget exceeded: $todo_words"

rows=0
total_reductions=
nonledger_reductions=
while IFS='|' read -r scenario baseline_total baseline_nonledger resources; do
    case $scenario in
        ''|'#'*) continue ;;
    esac
    rows=$((rows + 1))
    current_total=0
    current_nonledger=0
    selected_task_count=0
    selected_external=0
    old_ifs=$IFS
    IFS=,
    for relative in $resources; do
        path=$ROOT/$relative
        [ -f "$path" ] && [ ! -L "$path" ] ||
            fail "$scenario selected unsafe or missing resource: $relative"
        git -C "$ROOT" ls-files --error-unmatch -- "$relative" >/dev/null 2>&1 ||
            fail "$scenario selected untracked resource: $relative"
        count=$(words "$path")
        current_total=$((current_total + count))
        [ "$relative" = TODO.md ] ||
            current_nonledger=$((current_nonledger + count))
        case $relative in
            docs/tasks/T-351.md) selected_task_count=$((selected_task_count + 1)) ;;
            docs/tasks/T-*.md)
                fail "$scenario selected unrelated task record: $relative"
                ;;
            docs/agent-policy/external-operations.md) selected_external=1 ;;
        esac
    done
    IFS=$old_ifs

    [ "$selected_task_count" -eq 1 ] ||
        fail "$scenario did not select exactly one active task record"
    if [ "$scenario" = documentation-edit ]; then
        [ "$selected_external" -eq 1 ] ||
            fail 'documentation publication route omitted external policy'
    fi

    [ "$current_total" -lt "$baseline_total" ] ||
        fail "$scenario total context did not fall"
    [ "$current_nonledger" -lt "$baseline_nonledger" ] ||
        fail "$scenario non-ledger context did not fall"

    total_reduction=$(
        expr \( "$baseline_total" - "$current_total" \) \* 1000 / \
            "$baseline_total"
    )
    nonledger_reduction=$(
        expr \( "$baseline_nonledger" - "$current_nonledger" \) \* 1000 / \
            "$baseline_nonledger"
    )
    [ "$total_reduction" -ge 500 ] ||
        fail "$scenario total reduction below 50.0%: $total_reduction tenths"

    total_reductions="$total_reductions $total_reduction"
    nonledger_reductions="$nonledger_reductions $nonledger_reduction"
    printf 'CONTEXT scenario=%s before=%s after=%s reduction_tenths=%s nonledger_before=%s nonledger_after=%s nonledger_reduction_tenths=%s\n' \
        "$scenario" "$baseline_total" "$current_total" "$total_reduction" \
        "$baseline_nonledger" "$current_nonledger" "$nonledger_reduction"
done <"$SCENARIOS"

[ "$rows" -eq 8 ] || fail "expected 8 context scenarios, found $rows"

total_middle=$(printf '%s\n' $total_reductions | sort -n | sed -n '4p;5p')
nonledger_middle=$(
    printf '%s\n' $nonledger_reductions | sort -n | sed -n '4p;5p'
)
total_median=$(printf '%s\n' "$total_middle" | awk '{sum += $1} END {print int(sum / 2)}')
nonledger_median=$(
    printf '%s\n' "$nonledger_middle" |
        awk '{sum += $1} END {print int(sum / 2)}'
)

[ "$total_median" -ge 850 ] ||
    fail "median total reduction below 85.0%: $total_median tenths"
[ "$nonledger_median" -ge 300 ] ||
    fail "median non-ledger reduction below 30.0%: $nonledger_median tenths"

printf 'CONTEXT_ROUTING status=pass scenarios=%s median_total_tenths=%s median_nonledger_tenths=%s board_lines=%s board_words=%s\n' \
    "$rows" "$total_median" "$nonledger_median" "$todo_lines" "$todo_words"

python3 - "$ROOT" "$SCENARIOS" <<'PY'
from pathlib import Path
import re
import sys

if not __debug__:
    raise SystemExit("context benchmark table check requires Python assertions")

root = Path(sys.argv[1])
manifest = Path(sys.argv[2])
document = root / "docs/audits/t351-autonomy-efficiency/context-benchmark.md"
labels = {
    "factual-lookup": "factual lookup",
    "documentation-edit": "documentation edit",
    "ordinary-code-fix": "ordinary code fix",
    "tmux-health-diagnosis": "tmux health diagnosis",
    "unsafe-tail-recovery": "unsafe-tail recovery",
    "fleet-hardening": "fleet hardening",
    "native-hpc-experiment": "native HPC experiment",
    "duration-cowork": "duration Cowork",
}


def percentage(before, after):
    tenths = (before - after) * 1000 // before
    return f"{tenths // 10}.{tenths % 10}%"


expected = {}
total_reductions = []
nonledger_reductions = []
for raw in manifest.read_text(encoding="utf-8").splitlines():
    if not raw or raw.startswith("#"):
        continue
    scenario, baseline_total, baseline_nonledger, resources = raw.split("|")
    baseline_total = int(baseline_total)
    baseline_nonledger = int(baseline_nonledger)
    selected = resources.split(",")
    counts = {
        relative: len((root / relative).read_text(encoding="utf-8").split())
        for relative in selected
    }
    current_total = sum(counts.values())
    current_nonledger = current_total - counts["TODO.md"]
    total_tenths = (
        (baseline_total - current_total) * 1000 // baseline_total
    )
    nonledger_tenths = (
        (baseline_nonledger - current_nonledger) * 1000
        // baseline_nonledger
    )
    total_reductions.append(total_tenths)
    nonledger_reductions.append(nonledger_tenths)
    expected[labels[scenario]] = [
        f"{baseline_total:,}",
        f"{current_total:,}",
        percentage(baseline_total, current_total),
        f"{baseline_nonledger:,}",
        f"{current_nonledger:,}",
        percentage(baseline_nonledger, current_nonledger),
    ]

observed = {}
for line in document.read_text(encoding="utf-8").splitlines():
    match = re.fullmatch(
        r"\| ([^|]+) \| ([0-9,]+) \| ([0-9,]+) \| ([0-9.]+%) "
        r"\| ([0-9,]+) \| ([0-9,]+) \| ([0-9.]+%) \|",
        line,
    )
    if match and match.group(1) in expected:
        observed[match.group(1)] = list(match.groups()[1:])
assert observed == expected, (observed, expected)

total_sorted = sorted(total_reductions)
nonledger_sorted = sorted(nonledger_reductions)
total_median = sum(total_sorted[3:5]) // 2
nonledger_median = sum(nonledger_sorted[3:5]) // 2
normalized = " ".join(document.read_text(encoding="utf-8").split())
assert (
    f"The median total reduction is {total_median // 10}."
    f"{total_median % 10}%"
) in normalized
assert (
    f"Median non-ledger reduction is {nonledger_median // 10}."
    f"{nonledger_median % 10}%"
) in normalized
PY
