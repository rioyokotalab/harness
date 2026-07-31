#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PREFLIGHT=$ROOT/shared/skills/onboard-mirrored-node/scripts/onboard-preflight
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/onboard-test.XXXXXX")
SKILL_ROOT=$ROOT/shared/skills/onboard-mirrored-node
SKILL=$SKILL_ROOT/SKILL.md
PLANNING=$SKILL_ROOT/references/planning-interview.md
DECLARATION_PHASE=$SKILL_ROOT/references/declarations-phase.md
DECLARATIONS=$SKILL_ROOT/references/declarations.md
BOOTSTRAP=$SKILL_ROOT/references/bootstrap-migration.md
ACCEPTANCE=$SKILL_ROOT/references/backup-acceptance.md

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

expect_failure() {
    expected=$1
    output=$2
    shift 2
    if "$@" >"$output" 2>&1; then
        fail "command unexpectedly succeeded: $*"
    fi
    grep -F -- "$expected" "$output" >/dev/null ||
        fail "missing failure evidence '$expected': $*"
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
        printf '%s\n' 'FAIL: guarded onboarding-test cleanup' >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

sh -n "$PREFLIGHT" || fail "preflight shell syntax"

fixture_root=$TEST_ROOT/harness
fake_bin=$TEST_ROOT/bin
mkdir -p "$fixture_root/libexec" "$fixture_root/profiles/hosts" \
    "$fixture_root/shell/environments" "$fixture_root/tests/fixtures" "$fake_bin"
cp "$ROOT/libexec/harness-inventory" "$fixture_root/libexec/harness-inventory"
printf '%s\n' '# host|persistent-root|cache-root|move-large|move-fast|delete-after-backup|owner-action' \
    >"$fixture_root/profiles/home-layout.tsv"
printf '%s\n' '# host|primary-repository|independent-replica-root|password-file|replica-transport' \
    >"$fixture_root/profiles/restic-repositories.tsv"
printf '%s\n' '# host|scheduler|native-submit|state-root|warning-policy' \
    >"$fixture_root/profiles/restic-schedules.tsv"

HARNESS_ROOT="$fixture_root" "$PREFLIGHT" validate newnode9 \
    >"$TEST_ROOT/validate.out" || fail "valid new host rejected"
grep -F 'host=newnode9 boundary=ssh-alias-only status=accepted' \
    "$TEST_ROOT/validate.out" >/dev/null || fail "validation boundary marker"

for bad_host in local si web github abci_login alps_login Bad ../bad bad/name two..dots; do
    expect_failure '' "$TEST_ROOT/bad-host.out" env HARNESS_ROOT="$fixture_root" \
        "$PREFLIGHT" validate "$bad_host"
done

for profile in "$ROOT"/profiles/hosts/*.conf; do
    managed=${profile##*/}
    managed=${managed%.conf}
    if [ "$managed" = local ]; then
        expect_failure 'reserved or service' "$TEST_ROOT/managed.out" \
            "$PREFLIGHT" validate "$managed"
    else
        expect_failure 'already exists' "$TEST_ROOT/managed.out" \
            "$PREFLIGHT" validate "$managed"
    fi
done

: >"$fixture_root/shell/environments/shellnode.sh"
expect_failure 'already exists' "$TEST_ROOT/shell-collision.out" \
    env HARNESS_ROOT="$fixture_root" "$PREFLIGHT" validate shellnode
printf '%s\n' 'mapnode|/large|/cache|none|none|none|none' \
    >>"$fixture_root/profiles/home-layout.tsv"
expect_failure 'already exists' "$TEST_ROOT/map-collision.out" \
    env HARNESS_ROOT="$fixture_root" "$PREFLIGHT" validate mapnode

cat >"$fake_bin/ssh" <<'EOF'
#!/bin/sh
printf '%s\n' call >>"$FAKE_SSH_LOG"
[ "$#" -eq 4 ] || exit 90
[ "$1" = -o ] && [ "$2" = BatchMode=yes ] || exit 91
[ "$3" = newnode9 ] && [ "$4" = 'exec sh -s -- --host newnode9' ] || exit 92
case ${FAKE_SSH_MODE:-good} in
    good)
        printf '%s\n' schema=1 logical_host=newnode9 os_id=linux arch=x86_64 \
            login_shell=bash tool_sh=present tool_bash=present tool_git=present \
            harness_checkout=absent
        ;;
    duplicate)
        printf '%s\n' schema=1 schema=1 logical_host=newnode9 os_id=linux \
            arch=x86_64 login_shell=bash tool_sh=present tool_bash=present \
            tool_git=present harness_checkout=absent
        ;;
    wrong-host)
        printf '%s\n' schema=1 logical_host=other os_id=linux arch=x86_64 \
            login_shell=bash tool_sh=present tool_bash=present tool_git=present \
            harness_checkout=absent
        ;;
    hostile)
        printf '%s\n' schema=1 logical_host=newnode9 'os_id=linux value' \
            arch=x86_64 login_shell=bash tool_sh=present tool_bash=present \
            tool_git=present harness_checkout=absent
        ;;
    oversize)
        awk 'BEGIN { for (i=0; i<70000; i++) printf "x" }'
        ;;
    refused) exit 93 ;;
    *) exit 94 ;;
esac
EOF
chmod 700 "$fake_bin/ssh"

PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$fixture_root" TMPDIR="$TEST_ROOT" \
    FAKE_SSH_LOG="$TEST_ROOT/ssh.log" \
    "$PREFLIGHT" inventory newnode9 >"$TEST_ROOT/inventory.out" ||
    fail "valid value-free inventory rejected"
[ "$(wc -l <"$TEST_ROOT/ssh.log" | tr -d ' ')" -eq 1 ] ||
    fail "inventory used more than one SSH connection"
grep -Fx 'logical_host=newnode9' "$TEST_ROOT/inventory.out" >/dev/null ||
    fail "inventory logical identity"
for mode in duplicate wrong-host hostile oversize; do
    expect_failure 'inventory' "$TEST_ROOT/inventory-$mode.out" env \
        PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$fixture_root" TMPDIR="$TEST_ROOT" \
        FAKE_SSH_LOG="$TEST_ROOT/ssh.log" \
        FAKE_SSH_MODE="$mode" "$PREFLIGHT" inventory newnode9
done
expect_failure 'connection failed' "$TEST_ROOT/inventory-refused.out" env \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$fixture_root" TMPDIR="$TEST_ROOT" \
    FAKE_SSH_LOG="$TEST_ROOT/ssh.log" \
    FAKE_SSH_MODE=refused "$PREFLIGHT" inventory newnode9
if find "$TEST_ROOT" -maxdepth 1 -name 'harness-onboard.*' -print -quit |
    grep . >/dev/null 2>&1; then
    fail "preflight left a private inventory capture"
fi

for route in planning-interview declarations-phase declarations \
    bootstrap-migration backup-acceptance; do
    [ "$(grep -Fc "[$route.md](references/$route.md)" "$SKILL")" -eq 1 ] ||
        fail "missing or duplicate $route route"
done
grep -F 'select exactly one row' "$SKILL" >/dev/null ||
    fail "single current-phase route"
grep -F 'Do not preload later or unrelated phases' "$SKILL" >/dev/null ||
    fail "unloaded phases remain unloaded"
grep -F 'A phase change triggers only' "$SKILL" >/dev/null ||
    fail "new phase is the only reference trigger"
grep -F 'References never select one another' "$SKILL" >/dev/null ||
    fail "reference chaining forbidden"
if grep -E '\]\(references/(planning-interview|declarations-phase|declarations|bootstrap-migration|backup-acceptance)\.md\)' \
    "$PLANNING" "$DECLARATION_PHASE" "$DECLARATIONS" "$BOOTSTRAP" \
    "$ACCEPTANCE" >/dev/null; then
    fail "a phase reference triggers another reference"
fi

grep -F 'Plan–Interview–Execute' "$SKILL" >/dev/null || fail "PIE contract"
grep -F 'Never enumerate `~/.ssh/config`' "$SKILL" >/dev/null ||
    fail "SSH discovery boundary"
grep -F 'BatchMode SSH connection' "$PLANNING" >/dev/null ||
    fail "single value-free inventory connection"
grep -F 'Explicit `go` authorizes only the frozen plan' "$SKILL" >/dev/null ||
    fail "go authority boundary"
grep -F 'wait for explicit `go`' "$PLANNING" >/dev/null ||
    fail "explicit go gate"
grep -F 'Ask exactly one owner question at a time' "$PLANNING" >/dev/null ||
    fail "one-question interview"
grep -F 'Never request a secret' "$PLANNING" >/dev/null ||
    fail "credential-content boundary"
grep -F 'mode-0600 password file' "$PLANNING" >/dev/null ||
    fail "owner-only password checkpoint"
grep -F 'Scheduling is excluded' "$SKILL" >/dev/null ||
    fail "schedule exclusion"
grep -F 'Do not create scheduler jobs, cron entries, or schedule declarations' \
    "$PLANNING" >/dev/null || fail "scheduler mutation exclusion"
grep -F 'Never overwrite a declaration' "$DECLARATION_PHASE" >/dev/null ||
    fail "declaration collision gate"
grep -F 'Run every mutating Harness command in `plan` mode first' \
    "$BOOTSTRAP" >/dev/null || fail "transactional plan gate"
grep -F 'immediately before `apply`' "$BOOTSTRAP" >/dev/null ||
    fail "transactional apply revalidation"
grep -F 'guarded-bulk-delete skill' "$SKILL" >/dev/null ||
    fail "guarded cleanup contract"
grep -F 'independent encrypted generation' "$ACCEPTANCE" >/dev/null ||
    fail "independent backup generation"
grep -F 'primary snapshot/check/restore' "$ACCEPTANCE" >/dev/null ||
    fail "backup restore acceptance"
grep -F 'On gate failure' "$SKILL" >/dev/null ||
    fail "common failure behavior"
grep -F 'partial or ambiguous result' "$ACCEPTANCE" >/dev/null ||
    fail "ambiguous acceptance refusal"

words() {
    wc -w <"$1" | tr -d ' '
}

# Baseline at task start: the 829-word entry selected the 328-word declaration
# contract during planning, so both aggregate corpus and largest route were
# 1,157 words.
before_aggregate=1157
before_largest=1157
entry_words=$(words "$SKILL")
planning_words=$((entry_words + $(words "$PLANNING")))
declaration_words=$((entry_words + $(words "$DECLARATION_PHASE") +
    $(words "$DECLARATIONS")))
bootstrap_words=$((entry_words + $(words "$BOOTSTRAP")))
acceptance_words=$((entry_words + $(words "$ACCEPTANCE")))
after_aggregate=$((entry_words + $(words "$PLANNING") +
    $(words "$DECLARATION_PHASE") + $(words "$DECLARATIONS") +
    $(words "$BOOTSTRAP") + $(words "$ACCEPTANCE")))
after_largest=$planning_words
for selected in "$declaration_words" "$bootstrap_words" "$acceptance_words"; do
    [ "$selected" -le "$after_largest" ] || after_largest=$selected
done
[ "$after_aggregate" -le "$before_aggregate" ] ||
    fail "aggregate route corpus grew: $before_aggregate->$after_aggregate"
route_reduction=$(((before_largest - after_largest) * 100 / before_largest))
[ "$route_reduction" -ge 40 ] ||
    fail "largest selected route reduction is not material: $route_reduction%"

if grep -F '.ssh/config' "$PREFLIGHT" >/dev/null; then
    fail "preflight inspects SSH configuration"
fi

printf '%s\n' \
    "onboard skill context: aggregate $before_aggregate->$after_aggregate words; largest selected route $before_largest->$after_largest words (-$route_reduction%)"
printf '%s\n' 'onboard mirrored node tests passed'
