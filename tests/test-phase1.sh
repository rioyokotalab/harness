#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded phase-1 cleanup" >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

for script in \
    "$ROOT/bin/harness" \
    "$ROOT/libexec/harness-common" \
    "$ROOT/libexec/harness-inventory" \
    "$ROOT/libexec/harness-plan" \
    "$ROOT/libexec/harness-doctor" \
    "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-inventory" \
    "$ROOT/libexec/harness-macos-plan" \
    "$ROOT/libexec/harness-macos-doctor" \
    "$ROOT/libexec/harness-macos-profile" \
    "$ROOT/libexec/harness-macos-update" \
    "$ROOT/libexec/harness-macos-control" \
    "$ROOT/libexec/harness-storage-readiness" \
    "$ROOT/libexec/harness-replica" \
    "$ROOT/libexec/harness-repository-fingerprint" \
    "$ROOT/libexec/harness-restic" \
    "$ROOT/libexec/harness-restic-primary" \
    "$ROOT/libexec/harness-restic-schedule" \
    "$ROOT/libexec/harness-fleet-sync" \
    "$ROOT/libexec/harness-apply" \
    "$ROOT/libexec/harness-remediate" \
    "$ROOT/libexec/harness-shell" \
    "$ROOT/libexec/harness-cache-bootstrap" \
    "$ROOT/libexec/harness-dotfiles" \
    "$ROOT/libexec/harness-tool" \
    "$ROOT/libexec/harness-runtime" \
    "$ROOT/libexec/harness-python" \
    "$ROOT/libexec/harness-agent" \
    "$ROOT/libexec/harness-build-tool" \
    "$ROOT/shared/skills/guarded-bulk-delete/scripts/guarded-delete" \
    "$ROOT/shared/skills/onboard-mirrored-node/scripts/onboard-preflight" \
    "$ROOT/tests/guarded-test-cleanup.sh" \
    "$ROOT/tests/test-github-rulesets.sh" \
    "$ROOT/tests/test-claude-takeover.sh" \
    "$ROOT/tests/test-local-mpi-profile.sh" \
    "$ROOT/tests/test-repository-independence.sh" \
    "$ROOT/tests/test-remote-session.sh" \
    "$ROOT/tests/test-safety-guards.sh" \
    "$ROOT/tests/test-ssh-agent-profile.sh" \
    "$ROOT/tests/smoke/debugger-readiness.sh" \
    "$ROOT/tests/smoke/locked-venv-readiness.sh" \
    "$ROOT/tests/smoke/scientific-library-readiness.sh" \
    "$ROOT/tests/smoke/venv-readiness.sh" \
    "$ROOT/tests/smoke/jobs/checkpoint-restart-readiness.sh" \
    "$ROOT/tests/smoke/jobs/local-checkpoint-restart.slurm" \
    "$ROOT/tests/smoke/jobs/multinode-mpi-readiness.sh" \
    "$ROOT/tests/smoke/jobs/shared-executable-visibility.sh" \
    "$ROOT/tools/hpc-result-hygiene.sh" \
    "$ROOT/tools/hpc-job-preflight.sh" \
    "$ROOT/tools/hpc-topology-surface.sh" \
    "$ROOT/tests/smoke/jobs/source-contract.sh" \
    "$ROOT/libexec/harness-rollback"
do
    sh -n "$script" || fail "shell syntax: $script"
done

python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("'"$ROOT"'/libexec/harness-startup-normalize").read_text())' ||
    fail "Python syntax: harness-startup-normalize"

"$ROOT/tests/test-startup-normalize.sh" >/dev/null ||
    fail "startup normalization focused suite"
"$ROOT/tests/test-ssh-agent-profile.sh" >/dev/null ||
    fail "SSH agent profile focused suite"
"$ROOT/tests/test-remote-session.sh" >/dev/null ||
    fail "remote-session focused suite"
"$ROOT/tests/test-safety-guards.sh" >/dev/null ||
    fail "interactive safety-guard focused suite"
"$ROOT/tests/test-github-rulesets.sh" >/dev/null ||
    fail "GitHub ruleset payload focused suite"
"$ROOT/tests/test-repository-independence.sh" >/dev/null ||
    fail "repository independence focused suite"
"$ROOT/tests/test-claude-takeover.sh" >/dev/null ||
    fail "Claude takeover focused suite"
"$ROOT/tests/test-local-mpi-profile.sh" >/dev/null ||
    fail "local MPI profile focused suite"
"$ROOT/tests/test-personal-macos-profile.sh" >/dev/null ||
    fail "personal macOS private-profile focused suite"
"$ROOT/tests/test-personal-macos-inventory.sh" >/dev/null ||
    fail "personal macOS inventory focused suite"
"$ROOT/tests/test-personal-macos-plan-doctor.sh" >/dev/null ||
    fail "personal macOS plan/doctor focused suite"
"$ROOT/tests/test-personal-macos-control.sh" >/dev/null ||
    fail "personal macOS control-plane focused suite"
"$ROOT/tests/test-personal-macos-update.sh" >/dev/null ||
    fail "personal macOS long-gap update focused suite"

"$ROOT/tests/test-restic-schedule.sh" >/dev/null ||
    fail "Restic schedule focused suite"
"$ROOT/tests/test-onboard-mirrored-node.sh" >/dev/null ||
    fail "onboarding focused suite"
"$ROOT/tests/test-evaluation.sh" >/dev/null ||
    fail "evaluation focused suite"
"$ROOT/tests/test-public-repo-audit.sh" >/dev/null ||
    fail "public repository audit focused suite"
"$ROOT/tests/test-fleet-readiness-audit.sh" >/dev/null ||
    fail "fleet readiness audit focused suite"
"$ROOT/tests/test-hpc-readiness.sh" >/dev/null ||
    fail "HPC readiness job focused suite"
"$ROOT/tests/test-hpc-multinode-mpi-routes.sh" >/dev/null ||
    fail "multi-node MPI route focused suite"
"$ROOT/tests/test-multinode-mpi-readiness.sh" >/dev/null ||
    fail "multi-node MPI readiness focused suite"
"$ROOT/tests/test-shared-executable-visibility.sh" >/dev/null ||
    fail "shared executable visibility focused suite"
"$ROOT/tests/test-hpc-result-hygiene.sh" >/dev/null ||
    fail "HPC result hygiene focused suite"
"$ROOT/tests/test-hpc-job-preflight.sh" >/dev/null ||
    fail "HPC job preflight focused suite"
"$ROOT/tests/test-hpc-topology-surface.sh" >/dev/null ||
    fail "HPC topology surface focused suite"
"$ROOT/tests/test-hpc-project-intake.sh" >/dev/null ||
    fail "HPC project intake focused suite"
"$ROOT/tests/test-hpc-project-intake-validator.sh" >/dev/null ||
    fail "HPC project intake validator focused suite"
"$ROOT/tests/test-llm-hpc-next-actions.sh" >/dev/null ||
    fail "LLM/HPC next-action queue focused suite"
"$ROOT/tests/test-pytorch-lock.sh" >/dev/null ||
    fail "PyTorch dual-architecture lock focused suite"
"$ROOT/tests/test-pytorch-readiness.sh" >/dev/null ||
    fail "PyTorch single-device readiness focused suite"
"$ROOT/tests/test-storage-readiness.sh" >/dev/null ||
    fail "storage readiness focused suite"
"$ROOT/tests/test-debugger-readiness.sh" >/dev/null ||
    fail "debugger readiness focused suite"
"$ROOT/tests/test-venv-readiness.sh" >/dev/null ||
    fail "venv readiness focused suite"
"$ROOT/tests/test-locked-venv-readiness.sh" >/dev/null ||
    fail "locked venv readiness focused suite"
"$ROOT/tests/test-scientific-library-readiness.sh" >/dev/null ||
    fail "scientific library readiness focused suite"
"$ROOT/tests/test-fleet-sync.sh" >/dev/null ||
    fail "fleet sync focused suite"
"$ROOT/tests/test-checkpoint-restart.sh" >/dev/null ||
    fail "checkpoint restart focused suite"
"$ROOT/tests/test-hpc-cpu-routes.sh" >/dev/null ||
    fail "bounded CPU route focused suite"
"$ROOT/tests/test-source-contract.sh" >/dev/null ||
    fail "source contract focused suite"

# Direct non-interactive SSH can omit ~/.local/bin even when the managed
# Restic installation is healthy. The harness route must find that exact
# fallback, while retaining normal PATH precedence when a site command exists.
restic_route_home=$TEMP_DIR/restic-route-home
restic_route_path=$TEMP_DIR/restic-route-path
mkdir -p "$restic_route_home/.local/bin" "$restic_route_path"
cat >"$restic_route_home/.local/bin/restic" <<'EOF'
#!/bin/sh
printf 'managed|%s\n' "$*"
EOF
cat >"$restic_route_path/restic" <<'EOF'
#!/bin/sh
printf 'path|%s\n' "$*"
EOF
chmod 755 "$restic_route_home/.local/bin/restic" "$restic_route_path/restic"
restic_route_output=$(HOME="$restic_route_home" PATH=/usr/bin:/bin \
    "$HARNESS" restic version)
[ "$restic_route_output" = 'managed|version' ] ||
    fail "managed Restic fallback route"
restic_route_output=$(HOME="$restic_route_home" \
    PATH="$restic_route_path:/usr/bin:/bin" "$HARNESS" restic version)
[ "$restic_route_output" = 'path|version' ] ||
    fail "Restic PATH precedence route"
if HOME="$TEMP_DIR/restic-route-absent" PATH=/usr/bin:/bin \
    "$HARNESS" restic version >"$TEMP_DIR/restic-route-absent.out" 2>&1; then
    fail "Restic route accepted an absent command"
fi

for script in "$ROOT"/shell/cache.sh "$ROOT"/shell/common-aliases.sh \
    "$ROOT"/shell/early-cache.sh "$ROOT"/shell/module-stack.sh "$ROOT"/shell/profile.sh \
    "$ROOT"/shell/environments/*.sh; do
    sh -n "$script" || fail "shell configuration syntax: $script"
done
for script in "$ROOT"/shell/interactive.sh "$ROOT"/shell/remote-session.sh \
    "$ROOT"/shell/safety-guards.sh \
    "$ROOT"/shell/hosts/*.sh; do
    bash -n "$script" || fail "Bash configuration syntax: $script"
done

# The portable profile must remain silent and side-effect free in
# non-interactive sessions while exporting the selected node's roots.
profile_home=$TEMP_DIR/profile-home
mkdir -p "$profile_home/harness"
cp -R "$ROOT/shell" "$profile_home/harness/"
profile_output=$(HOME="$profile_home" PATH=/usr/bin:/bin \
    HARNESS_LOGICAL_HOST=ab sh -c \
    '. "$HOME/harness/shell/profile.sh"; printf "%s|%s|%s\n" "$HARNESS_PERSISTENT_ROOT" "$HARNESS_CACHE_ROOT" "$XDG_CACHE_HOME"')
[ "$profile_output" = \
    '/groups/gag51395/yokota|/groups/gag51395/yokota/cache|/groups/gag51395/yokota/cache/xdg' ] ||
    fail "portable non-interactive profile"
[ ! -e "$profile_home/.cache" ] || fail "profile created a cache directory"

# A top-level interactive SSH shell receives only the Ctrl-D guard. Git
# synchronization/publication is explicit and exit remains Bash's builtin.
remote_type=$(env -u SHLVL -u HARNESS_INTERACTIVE_LOADED \
    -u HARNESS_REMOTE_SESSION_LOADED -u TMUX \
    HOME="$profile_home" PATH=/usr/bin:/bin \
    SSH_TTY=/dev/pts/test \
    HARNESS_LOGICAL_HOST=ab bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; printf "%s|%s|%s\n" "$(type -t exit)" "$IGNOREEOF" "$HARNESS_LOGICAL_HOST"' \
    2>/dev/null)
[ "$remote_type" = 'builtin|1|ab' ] || fail "interactive remote-session policy"

# Interactive login must not invoke Git, even when a checkout and an apparent
# forwarded agent are present.
explicit_git_home=$TEMP_DIR/explicit-git-home
mkdir -p "$explicit_git_home/harness/.git" "$explicit_git_home/.local/bin"
cp -R "$ROOT/shell" "$explicit_git_home/harness/"
login_git_log=$TEMP_DIR/login-git.log
cat >"$explicit_git_home/.local/bin/git" <<'EOF'
#!/bin/sh
printf '%s\n' invoked >>"$LOGIN_GIT_LOG"
exit 99
EOF
chmod 755 "$explicit_git_home/.local/bin/git"
explicit_git_output=$(env -u SHLVL \
    -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED -u TMUX \
    HOME="$explicit_git_home" PATH=/usr/bin:/bin SSH_TTY=/dev/pts/test \
    SSH_AUTH_SOCK=/tmp/forwarded-agent.sock HARNESS_LOGICAL_HOST=ab \
    LOGIN_GIT_LOG="$login_git_log" \
    bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; printf "%s\n" login-ready' 2>/dev/null)
[ "$explicit_git_output" = login-ready ] || fail "explicit Git login policy"
[ ! -e "$login_git_log" ] || fail "interactive login invoked Git"

tmux_type=$(env -u SHLVL -u HARNESS_INTERACTIVE_LOADED \
    -u HARNESS_REMOTE_SESSION_LOADED HOME="$profile_home" PATH=/usr/bin:/bin \
    SSH_TTY=/dev/pts/test \
    TMUX=/tmp/tmux HARNESS_LOGICAL_HOST=ab bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; type -t exit' 2>/dev/null)
[ "$tmux_type" = builtin ] || fail "tmux session unexpectedly overrides exit"

remote_codex_home=$TEMP_DIR/remote-codex-home
remote_codex_bin=$TEMP_DIR/remote-codex-bin
remote_codex_log=$TEMP_DIR/remote-codex.log
mkdir -p "$remote_codex_home/harness/profiles/hosts" "$remote_codex_bin"
cp -R "$ROOT/shell" "$remote_codex_home/harness/"
cp "$ROOT/profiles/hosts/ab.conf" "$remote_codex_home/harness/profiles/hosts/"
cp "$ROOT/profiles/hosts/ab.conf" \
    "$remote_codex_home/harness/profiles/hosts/invented.conf"
cat >"$remote_codex_bin/ssh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$REMOTE_CODEX_LOG"
EOF
chmod 755 "$remote_codex_bin/ssh"
env -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$remote_codex_home" PATH="$remote_codex_bin:/usr/bin:/bin" \
    REMOTE_CODEX_LOG="$remote_codex_log" HARNESS_LOGICAL_HOST=local \
    bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; harness_remote_codex ab' 2>/dev/null
[ "$(cat "$remote_codex_log")" = \
    "-A -t ab exec bash -lic 'cd \"\$HOME\" && exec codex'" ] ||
    fail "one-connection remote Codex launcher"
env -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$remote_codex_home" PATH="$remote_codex_bin:/usr/bin:/bin" \
    REMOTE_CODEX_LOG="$remote_codex_log" HARNESS_LOGICAL_HOST=local \
    bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; harness_remote_codex invented' 2>/dev/null
[ "$(cat "$remote_codex_log")" = \
    "-A -t invented exec bash -lic 'cd \"\$HOME\" && exec codex'" ] ||
    fail "profile-derived remote Codex fleet membership"
if env -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$remote_codex_home" PATH="$remote_codex_bin:/usr/bin:/bin" \
    REMOTE_CODEX_LOG="$remote_codex_log" HARNESS_LOGICAL_HOST=local \
    bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; harness_remote_codex github' \
    >/dev/null 2>&1; then
    fail "remote Codex launcher accepted an excluded service"
fi

if command -v shellcheck >/dev/null 2>&1; then
    git -C "$ROOT" grep -Il -z '^#!.*\(sh\|bash\)' -- . \
        ':(exclude)tests/fixtures/**' |
        xargs -0 shellcheck --severity=warning || fail "ShellCheck warning/error gate"
fi

for script in \
    "$ROOT/libexec/harness-rollback" \
    "$ROOT/libexec/harness-shell" \
    "$ROOT/libexec/harness-cache-bootstrap" \
    "$ROOT/libexec/harness-tool" \
    "$ROOT/libexec/harness-runtime" \
    "$ROOT/libexec/harness-python" \
    "$ROOT/libexec/harness-agent" \
    "$ROOT/libexec/harness-build-tool" \
    "$ROOT/tests/smoke/jobs/local.slurm"
do
    if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive' "$script" >/dev/null; then
        fail "raw recursive removal remains: $script"
    fi
done

"$ROOT/tests/test-guarded-delete.sh" || fail "guarded-delete regression suite"

replica_generation=20260715T120000Z
"$HARNESS" replica plan --host local --generation "$replica_generation" \
    >"$TEMP_DIR/replica-local.out" || fail "local replica plan"
grep -F "SOURCE scope=local transport=none path=/mnt/nfs-03/safe/Users/rioyokota/restic/home-control" \
    "$TEMP_DIR/replica-local.out" >/dev/null || fail "local replica source route"
grep -F "DESTINATION scope=remote transport=t4 root=/gs/bs/jh250019/yokota/restic-replicas/local" \
    "$TEMP_DIR/replica-local.out" >/dev/null || fail "local replica destination route"
grep -F "NATIVE rsync -aH -- '/mnt/nfs-03/safe/Users/rioyokota/restic/home-control/' 't4:/gs/bs/jh250019/yokota/restic-replicas/local/.staging-$replica_generation/'" \
    "$TEMP_DIR/replica-local.out" >/dev/null || fail "local replica native command"

"$HARNESS" replica plan --host ri --generation "$replica_generation" \
    >"$TEMP_DIR/replica-remote.out" || fail "remote replica plan"
grep -F "SOURCE scope=remote transport=ri path=/data1/rkp00015/rku00075/restic/home-control" \
    "$TEMP_DIR/replica-remote.out" >/dev/null || fail "remote replica source route"
grep -F "DESTINATION scope=local transport=none root=/mnt/nfs-03/safe/Users/rioyokota/restic-replicas/ri" \
    "$TEMP_DIR/replica-remote.out" >/dev/null || fail "remote replica destination route"
grep -F "NATIVE rsync -aH -- 'ri:/data1/rkp00015/rku00075/restic/home-control/' '/mnt/nfs-03/safe/Users/rioyokota/restic-replicas/ri/.staging-$replica_generation/'" \
    "$TEMP_DIR/replica-remote.out" >/dev/null || fail "remote replica native command"
if grep -E -- '--delete|home-control\.password' "$TEMP_DIR"/replica-*.out >/dev/null; then
    fail "replica plan exposed a password path or deletion option"
fi
"$HARNESS" replica plan --host ab2 --generation "$replica_generation" \
    >"$TEMP_DIR/replica-ab2.out" || fail "AB2 replica plan"
grep -F "SOURCE scope=remote transport=ab2 path=/groups/gah51624/yokota/restic/home-control" \
    "$TEMP_DIR/replica-ab2.out" >/dev/null || fail "AB2 replica source route"
grep -F "DESTINATION scope=local transport=none root=/mnt/nfs-03/safe/Users/rioyokota/restic-replicas/ab2" \
    "$TEMP_DIR/replica-ab2.out" >/dev/null || fail "AB2 replica destination route"
grep -F "NATIVE rsync -aH -- 'ab2:/groups/gah51624/yokota/restic/home-control/' '/mnt/nfs-03/safe/Users/rioyokota/restic-replicas/ab2/.staging-$replica_generation/'" \
    "$TEMP_DIR/replica-ab2.out" >/dev/null || fail "AB2 replica native command"
if "$HARNESS" replica plan --host local --generation 20260230T120000Z \
    >"$TEMP_DIR/replica-date.out" 2>&1; then
    fail "replica plan accepted an invalid timestamp"
fi

replica_repo=$TEMP_DIR/replica-harness
replica_source=$TEMP_DIR/replica-source
replica_destination=$TEMP_DIR/replica-destination
replica_local_destination=$TEMP_DIR/replica-local-destination
replica_remote_home=$TEMP_DIR/replica-remote-home
replica_fake_bin=$TEMP_DIR/replica-fake-bin
mkdir -p "$replica_repo" "$replica_source" "$replica_destination" \
    "$replica_local_destination" \
    "$replica_remote_home" "$replica_fake_bin"
cp -R "$ROOT/bin" "$ROOT/libexec" "$ROOT/profiles" "$replica_repo/"
awk -F'|' -v OFS='|' -v source="$replica_source" -v destination="$replica_destination" '
    $1 == "ri" { $2=source; $3=destination }
    $1 == "local" { $2=source; $3=local_destination }
    { print }
' local_destination="$replica_local_destination" \
    "$ROOT/profiles/restic-repositories.tsv" \
    >"$replica_repo/profiles/restic-repositories.tsv"
ln -s "$replica_repo" "$replica_remote_home/harness"
for directory in data index keys locks snapshots; do
    mkdir "$replica_source/$directory"
done
printf '%s\n' 'synthetic encrypted config' >"$replica_source/config"
printf '%s\n' 'synthetic encrypted object' >"$replica_source/data/object"
cat >"$replica_fake_bin/ssh" <<'EOF'
#!/bin/sh
[ "$1" = -o ] && [ "$2" = BatchMode=yes ] || exit 90
shift 2
case "$1" in ri|t4) ;; *) exit 91 ;; esac
shift
[ "$#" -eq 1 ] || exit 92
HOME=$FAKE_REMOTE_HOME sh -c "$1"
EOF
cat >"$replica_fake_bin/rsync" <<'EOF'
#!/bin/sh
[ "$1" = -aH ] && [ "$2" = -- ] || exit 93
source=${3#*:}
destination=${4#*:}
cp -a "$source/." "$destination/"
case ${FAKE_RSYNC_MODE:-clean} in
    clean) ;;
    corrupt) printf '%s\n' corrupt >>"$destination/config" ;;
    drift) printf '%s\n' drift >>"$source/config" ;;
    *) exit 94 ;;
esac
EOF
chmod 755 "$replica_fake_bin/ssh" "$replica_fake_bin/rsync"

PATH="$replica_fake_bin:$PATH" FAKE_REMOTE_HOME="$replica_remote_home" \
    "$replica_repo/bin/harness" replica apply --host ri \
    --generation 20260715T120001Z >"$TEMP_DIR/replica-apply.out" ||
    fail "synthetic replica apply"
[ -d "$replica_destination/20260715T120001Z" ] || fail "replica generation promotion"
[ ! -e "$replica_destination/.staging-20260715T120001Z" ] ||
    fail "replica staging remained after success"
[ "$("$replica_repo/libexec/harness-repository-fingerprint" "$replica_source")" = \
    "$("$replica_repo/libexec/harness-repository-fingerprint" "$replica_destination/20260715T120001Z")" ] ||
    fail "replica final fingerprint"
PATH="$replica_fake_bin:$PATH" FAKE_REMOTE_HOME="$replica_remote_home" \
    "$replica_repo/bin/harness" replica apply --host local \
    --generation 20260715T120001Z >"$TEMP_DIR/replica-local-apply.out" ||
    fail "synthetic local-to-remote replica apply"
[ -d "$replica_local_destination/20260715T120001Z" ] ||
    fail "local-to-remote replica generation promotion"
[ ! -e "$replica_local_destination/.staging-20260715T120001Z" ] ||
    fail "local-to-remote staging remained after success"
if PATH="$replica_fake_bin:$PATH" FAKE_REMOTE_HOME="$replica_remote_home" \
    "$replica_repo/bin/harness" replica apply --host ri \
    --generation 20260715T120001Z >"$TEMP_DIR/replica-collision.out" 2>&1; then
    fail "replica apply accepted a final-path collision"
fi

if PATH="$replica_fake_bin:$PATH" FAKE_REMOTE_HOME="$replica_remote_home" \
    FAKE_RSYNC_MODE=corrupt "$replica_repo/bin/harness" replica apply --host ri \
    --generation 20260715T120002Z >"$TEMP_DIR/replica-corrupt.out" 2>&1; then
    fail "replica apply promoted a mismatched copy"
fi
[ -d "$replica_destination/.staging-20260715T120002Z" ] ||
    fail "mismatched replica staging was not retained"
[ ! -e "$replica_destination/20260715T120002Z" ] ||
    fail "mismatched replica was promoted"

if PATH="$replica_fake_bin:$PATH" FAKE_REMOTE_HOME="$replica_remote_home" \
    FAKE_RSYNC_MODE=drift "$replica_repo/bin/harness" replica apply --host ri \
    --generation 20260715T120003Z >"$TEMP_DIR/replica-drift.out" 2>&1; then
    fail "replica apply ignored source drift"
fi
[ -d "$replica_destination/.staging-20260715T120003Z" ] ||
    fail "source-drift staging was not retained"
[ ! -e "$replica_destination/20260715T120003Z" ] ||
    fail "source-drift replica was promoted"

printf '%s\n' active >"$replica_source/locks/active"
if PATH="$replica_fake_bin:$PATH" FAKE_REMOTE_HOME="$replica_remote_home" \
    "$replica_repo/bin/harness" replica apply --host ri \
    --generation 20260715T120004Z >"$TEMP_DIR/replica-lock.out" 2>&1; then
    fail "replica apply accepted an active or stale Restic lock"
fi
[ ! -e "$replica_destination/.staging-20260715T120004Z" ] ||
    fail "replica staging was created despite a Restic lock"
unlink "$replica_source/locks/active"

ln -s config "$replica_source/config-link"
if PATH="$replica_fake_bin:$PATH" FAKE_REMOTE_HOME="$replica_remote_home" \
    "$replica_repo/bin/harness" replica apply --host ri \
    --generation 20260715T120005Z >"$TEMP_DIR/replica-symlink.out" 2>&1; then
    fail "replica apply accepted a repository symlink"
fi
[ ! -e "$replica_destination/.staging-20260715T120005Z" ] ||
    fail "replica staging was created despite a source symlink"
unlink "$replica_source/config-link"

python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' \
    "$ROOT/tests/smoke/llm_torch.py" ||
    fail "LLM PyTorch smoke syntax"
python3 "$ROOT/tests/smoke/llm_torch.py" --help \
    >"$TEMP_DIR/llm-torch-help.out" || fail "LLM PyTorch smoke help"
grep -- '--require-world-size' "$TEMP_DIR/llm-torch-help.out" >/dev/null ||
    fail "LLM PyTorch smoke world-size gate"

cc -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
    "$ROOT/tests/smoke/sanitizer.c" -o "$TEMP_DIR/sanitizer"
[ "$("$TEMP_DIR/sanitizer")" = sanitizer=pass ] ||
    fail "native sanitizer smoke"
c++ -std=c++20 -O2 "$ROOT/tests/smoke/cpp20.cpp" -o "$TEMP_DIR/cpp20"
[ "$("$TEMP_DIR/cpp20")" = cpp20=pass ] || fail "native C++20 smoke"
case ${HARNESS_PORTABLE_CI:-0} in
    0)
        mpicc -O2 "$ROOT/tests/smoke/mpi.c" -o "$TEMP_DIR/mpi"
        [ "$("$TEMP_DIR/mpi" 1)" = "mpi=pass ranks=1" ] ||
            fail "native MPI singleton smoke"
        mpicc -O2 "$ROOT/tests/smoke/mpi-multinode.c" -o "$TEMP_DIR/mpi-multinode" ||
            fail "native multi-node MPI source compile"
        ;;
    1)
        printf '%s\n' 'SKIP native MPI singleton smoke: portable CI has no declared MPI toolchain'
        ;;
    *)
        fail "HARNESS_PORTABLE_CI must be 0 or 1"
        ;;
esac

"$HARNESS" inventory --host local >"$TEMP_DIR/local.facts"
awk -F= '
    NF != 2 { exit 1 }
    $1 !~ /^[A-Za-z0-9_]+$/ { exit 1 }
    $2 !~ /^[A-Za-z0-9._+-]+$/ { exit 1 }
' "$TEMP_DIR/local.facts" || fail "unsafe inventory fact format"
if grep -F "$HOME" "$TEMP_DIR/local.facts" >/dev/null 2>&1; then
    fail "inventory exposed a home path"
fi
cut -d= -f1 "$TEMP_DIR/local.facts" | LC_ALL=C sort -u \
    >"$TEMP_DIR/allowed-keys"

"$HARNESS" inventory --host local --format json >"$TEMP_DIR/local.json"
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["schema"] == "1"' \
    "$TEMP_DIR/local.json" || fail "invalid JSON inventory"

for profile in "$ROOT"/profiles/hosts/*.conf; do
    [ -f "$profile" ] && [ ! -L "$profile" ] ||
        fail "managed profile is not a strict regular file: $profile"
    logical_host=${profile##*/}
    logical_host=${logical_host%.conf}
    [ -f "$ROOT/shell/environments/$logical_host.sh" ] ||
        fail "missing environment declaration: $logical_host"
    [ -f "$ROOT/shell/bashrc.$logical_host.block" ] ||
        fail "missing Bash rc declaration: $logical_host"
    [ -f "$ROOT/shell/bash_profile.$logical_host.block" ] ||
        fail "missing Bash profile declaration: $logical_host"
    fixture=$ROOT/tests/fixtures/$logical_host.facts
    [ -f "$fixture" ] || fail "missing fixture: $logical_host"
    awk -F= '
        NF != 2 { exit 1 }
        $1 !~ /^[A-Za-z0-9_]+$/ { exit 1 }
        $2 !~ /^[A-Za-z0-9._+-]+$/ { exit 1 }
    ' "$fixture" || fail "unsafe fixture fact format: $logical_host"
    cut -d= -f1 "$fixture" | LC_ALL=C sort >"$TEMP_DIR/fixture-keys"
    if uniq -d "$TEMP_DIR/fixture-keys" | grep . >/dev/null 2>&1; then
        fail "duplicate fixture fact: $logical_host"
    fi
    if comm -23 "$TEMP_DIR/fixture-keys" "$TEMP_DIR/allowed-keys" |
        grep . >/dev/null 2>&1; then
        fail "unknown fixture fact: $logical_host"
    fi
    "$HARNESS" doctor --host "$logical_host" --facts "$fixture" \
        >"$TEMP_DIR/doctor-$logical_host.out" ||
        fail "doctor rejected fixture: $logical_host"
    grep "SUMMARY host=$logical_host failures=0" \
        "$TEMP_DIR/doctor-$logical_host.out" >/dev/null ||
        fail "doctor summary: $logical_host"
    "$HARNESS" plan --host "$logical_host" --facts "$fixture" \
        >"$TEMP_DIR/plan-$logical_host.out" ||
        fail "plan rejected fixture: $logical_host"
    grep "END plan host=$logical_host remote_changes=none" \
        "$TEMP_DIR/plan-$logical_host.out" >/dev/null ||
        fail "plan mutation marker: $logical_host"
done

for profile in "$ROOT"/profiles/hosts/*.conf; do
    basename "$profile" .conf
done | LC_ALL=C sort >"$TEMP_DIR/profile-hosts"
sed '/^#/d' "$ROOT/profiles/home-layout.tsv" | cut -d'|' -f1 |
    LC_ALL=C sort >"$TEMP_DIR/home-layout-hosts"
cmp -s "$TEMP_DIR/profile-hosts" "$TEMP_DIR/home-layout-hosts" ||
    fail "home-layout hosts must exactly match managed profiles"
sed '/^#/d' "$ROOT/profiles/restic-repositories.tsv" | cut -d'|' -f1 |
    LC_ALL=C sort >"$TEMP_DIR/restic-hosts"
cmp -s "$TEMP_DIR/profile-hosts" "$TEMP_DIR/restic-hosts" ||
    fail "Restic repository hosts must exactly match managed profiles"

restic_rows=$(awk -F'|' '
    /^#/ { next }
    NF != 5 { exit 1 }
    $1 !~ /^[A-Za-z0-9._-]+$/ { exit 1 }
    $2 !~ /^\// || $3 !~ /^\// { exit 1 }
    $4 != "~/.config/restic/home-control.password" { exit 1 }
    $5 !~ /^(local|t4)$/ { exit 1 }
    { count[$1]++; rows++ }
    END {
        for (host in count) if (count[host] != 1) exit 1
        print rows
    }
' "$ROOT/profiles/restic-repositories.tsv")
[ "$restic_rows" -eq "$(wc -l <"$TEMP_DIR/profile-hosts" | tr -d ' ')" ] ||
    fail "Restic repository map must declare every managed profile"
[ "$(sed '/^#/d' "$ROOT/profiles/restic-repositories.tsv" | cut -d'|' -f2 | sort | uniq -d | wc -l)" -eq 0 ] ||
    fail "Restic primary repositories must be unique"

grep 'CREATE harness_checkout' "$TEMP_DIR/plan-al.out" >/dev/null ||
    fail "remote checkout plan"
grep 'INSTALL tool=uv' "$TEMP_DIR/plan-al.out" >/dev/null ||
    fail "remote uv plan"
grep 'KEEP site_command class=container command=apptainer' \
    "$TEMP_DIR/plan-ri.out" >/dev/null || fail "RIKEN Apptainer route"
grep 'WARN site_command class=container command=docker state=unusable' \
    "$TEMP_DIR/plan-local.out" >/dev/null || fail "compute-only Docker evidence"
grep 'WARN site_command class=container command=podman state=unusable' \
    "$TEMP_DIR/plan-local.out" >/dev/null || fail "compute-only Podman evidence"
grep 'KEEP site_command class=debugger command=cuda-gdb' \
    "$TEMP_DIR/plan-ab.out" >/dev/null || fail "hyphenated debugger fact mapping"
grep 'KEEP site_command class=profiler command=nsys' \
    "$TEMP_DIR/plan-ab.out" >/dev/null || fail "ABCI Nsight profile"
grep 'KEEP site_command class=profiler command=perf' \
    "$TEMP_DIR/plan-al.out" >/dev/null || fail "Alps perf profile"
grep 'KEEP site_command class=debugger command=gdb' \
    "$TEMP_DIR/plan-ri.out" >/dev/null || fail "RIKEN debugger profile"
grep 'KEEP tool=git-lfs command=git-lfs' "$TEMP_DIR/plan-rc.out" >/dev/null ||
    fail "hyphenated selected-tool fact mapping"
grep 'INSTALL tool=git-lfs command=git-lfs .*reason=host-command-unusable' \
    "$TEMP_DIR/plan-ri.out" >/dev/null || fail "unusable hyphenated selected tool"
grep 'KEEP tool=node command=node' "$TEMP_DIR/plan-local.out" >/dev/null ||
    fail "exact pinned Node aggregate plan"
grep 'KEEP tool=npm command=npm' "$TEMP_DIR/plan-local.out" >/dev/null ||
    fail "exact pinned npm aggregate plan"
sed 's/^arch=x86_64$/arch=aarch64/' "$ROOT/tests/fixtures/local.facts" \
    >"$TEMP_DIR/wrong-arch.facts"
if "$HARNESS" doctor --host local --facts "$TEMP_DIR/wrong-arch.facts" \
    >"$TEMP_DIR/wrong-arch.out" 2>&1; then
    fail "doctor accepted an architecture mismatch"
fi
grep 'FAIL arch expected=x86_64 observed=aarch64' \
    "$TEMP_DIR/wrong-arch.out" >/dev/null ||
    fail "architecture mismatch evidence"

if "$HARNESS" doctor --host excluded-host >"$TEMP_DIR/excluded.out" 2>&1; then
    fail "doctor accepted an unknown host"
fi

"$HARNESS" tool --host ab2 --name ripgrep --facts "$ROOT/tests/fixtures/ab2.facts" \
    --plan >"$TEMP_DIR/tool-plan.out"
grep 'INSTALL artifact=.*ripgrep/15.1.0/linux-x86_64' \
    "$TEMP_DIR/tool-plan.out" >/dev/null || fail "tool artifact plan"
grep 'sha256=1c9297be4a084eea7ecaedf93eb03d058d6faae29bbc57ecdaf5063921491599' \
    "$TEMP_DIR/tool-plan.out" >/dev/null || fail "tool checksum plan"
if "$HARNESS" tool --host ab2 --name unsupported \
    --facts "$ROOT/tests/fixtures/ab2.facts" --plan \
    >"$TEMP_DIR/unsupported-tool.out" 2>&1; then
    fail "tool plan accepted an unsupported artifact"
fi
mkdir -p "$TEMP_DIR/uv-plan-home"
HOME="$TEMP_DIR/uv-plan-home" "$HARNESS" tool --host al --name uv \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/uv-plan.out"
grep 'INSTALL artifact=.*uv/0.9.18/linux-aarch64' "$TEMP_DIR/uv-plan.out" \
    >/dev/null || fail "uv AArch64 artifact plan"
grep 'sha256=f8e23ec786b18660ade6b033b6191b7e9c283c872eeb8c4531d56a873decf160' \
    "$TEMP_DIR/uv-plan.out" >/dev/null || fail "uv AArch64 checksum plan"

mkdir -p "$TEMP_DIR/shellcheck-plan-home"
HOME="$TEMP_DIR/shellcheck-plan-home" "$HARNESS" tool --host local --name shellcheck \
    --facts "$ROOT/tests/fixtures/local.facts" --plan \
    >"$TEMP_DIR/shellcheck-x86-plan.out"
grep 'sha256=b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6' \
    "$TEMP_DIR/shellcheck-x86-plan.out" >/dev/null ||
    fail "ShellCheck x86-64 checksum plan"
grep 'EXTRACT format=tar.gz member=shellcheck-v0.11.0/shellcheck binary=shellcheck' \
    "$TEMP_DIR/shellcheck-x86-plan.out" >/dev/null ||
    fail "ShellCheck x86-64 extraction plan"
HOME="$TEMP_DIR/shellcheck-plan-home" "$HARNESS" tool --host al --name shellcheck \
    --facts "$ROOT/tests/fixtures/al.facts" --plan \
    >"$TEMP_DIR/shellcheck-arm-plan.out"
grep 'sha256=68a8133197a50beb8803f8d42f9908d1af1c5540d4bb05fdfca8c1fa47decefc' \
    "$TEMP_DIR/shellcheck-arm-plan.out" >/dev/null ||
    fail "ShellCheck AArch64 checksum plan"

mkdir -p "$TEMP_DIR/rclone-plan-home"
HOME="$TEMP_DIR/rclone-plan-home" "$HARNESS" tool --host rc --name rclone \
    --facts "$ROOT/tests/fixtures/rc.facts" --plan >"$TEMP_DIR/rclone-x86-plan.out"
grep 'sha256=dbee7ccd7a5d617e4ed4cd4555c16669b511abfe8d31164f61be35ac9e999bd2' \
    "$TEMP_DIR/rclone-x86-plan.out" >/dev/null || fail "rclone x86-64 checksum plan"
grep 'EXTRACT format=zip member=rclone-v1.74.3-linux-amd64/rclone binary=rclone' \
    "$TEMP_DIR/rclone-x86-plan.out" >/dev/null || fail "rclone x86-64 extraction plan"
HOME="$TEMP_DIR/rclone-plan-home" "$HARNESS" tool --host al --name rclone \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/rclone-arm-plan.out"
grep 'sha256=8f8d47446e061f80c3256659fe8e21f56d72d96aaefe1275d088ea5eb6b42aa7' \
    "$TEMP_DIR/rclone-arm-plan.out" >/dev/null || fail "rclone AArch64 checksum plan"
grep 'EXTRACT format=zip member=rclone-v1.74.3-linux-arm64/rclone binary=rclone' \
    "$TEMP_DIR/rclone-arm-plan.out" >/dev/null || fail "rclone AArch64 extraction plan"

mkdir -p "$TEMP_DIR/restic-plan-home"
HOME="$TEMP_DIR/restic-plan-home" "$HARNESS" tool --host local --name restic \
    --facts "$ROOT/tests/fixtures/local.facts" --plan \
    >"$TEMP_DIR/restic-x86-plan.out"
grep 'sha256=f415415624dcc452f2a02b8c33641791a8c6d6d3b65bbb3543fcf9a25151585c' \
    "$TEMP_DIR/restic-x86-plan.out" >/dev/null || fail "Restic x86-64 checksum plan"
HOME="$TEMP_DIR/restic-plan-home" "$HARNESS" tool --host al --name restic \
    --facts "$ROOT/tests/fixtures/al.facts" --plan \
    >"$TEMP_DIR/restic-arm-plan.out"
grep 'sha256=a5f64aaab53d51e311fa3829124c5b703f2d14cf187d8640b6be3b2b49376465' \
    "$TEMP_DIR/restic-arm-plan.out" >/dev/null || fail "Restic AArch64 checksum plan"
grep 'EXTRACT format=bz2 member=restic binary=restic' \
    "$TEMP_DIR/restic-arm-plan.out" >/dev/null || fail "Restic bzip2 extraction plan"

broken_bin=$TEMP_DIR/broken-bin
broken_home=$TEMP_DIR/broken-home
mkdir -p "$broken_bin" "$broken_home"
printf '%s\n' '#!/bin/sh' 'exit 1' >"$broken_bin/ninja"
chmod 755 "$broken_bin/ninja"
printf '%s\n' '#!/bin/sh' 'exit 1' >"$broken_bin/podman"
chmod 755 "$broken_bin/podman"
HOME="$broken_home" PATH="$broken_bin:/usr/bin:/bin" \
    "$HARNESS" inventory --host local >"$TEMP_DIR/unusable-container-inventory.out"
grep '^tool_podman=unusable$' "$TEMP_DIR/unusable-container-inventory.out" \
    >/dev/null || fail "container version health probe"
HOME="$broken_home" PATH="$broken_bin:/usr/bin:/bin" \
    "$HARNESS" tool --host local --name ninja --plan \
    >"$TEMP_DIR/ninja-unusable-plan.out"
grep 'SHADOW command=ninja reason=host-command-unusable strategy=user-path' \
    "$TEMP_DIR/ninja-unusable-plan.out" >/dev/null || fail "unusable host Ninja plan"
grep 'INSTALL artifact=.*ninja/1.13.2/linux-x86_64' \
    "$TEMP_DIR/ninja-unusable-plan.out" >/dev/null || fail "Ninja artifact plan"
grep 'sha256=5749cbc4e668273514150a80e387a957f933c6ed3f5f11e03fb30955e2bbead6' \
    "$TEMP_DIR/ninja-unusable-plan.out" >/dev/null || fail "Ninja x86-64 checksum plan"
printf '%s\n' '#!/bin/sh' 'echo "git-lfs/3.4.1 (fixture)"' >"$broken_bin/git-lfs"
chmod 755 "$broken_bin/git-lfs"
HOME="$broken_home" PATH="$broken_bin:/usr/bin:/bin" \
    "$HARNESS" tool --host local --name git-lfs --plan \
    >"$TEMP_DIR/git-lfs-live-old-plan.out"
grep 'SHADOW command=git-lfs reason=host-command-unusable strategy=user-path' \
    "$TEMP_DIR/git-lfs-live-old-plan.out" >/dev/null || fail "Git LFS live security floor"
printf '%s\n' '#!/bin/sh' 'echo "git-lfs/3.8.0 (fixture)"' >"$broken_bin/git-lfs"
HOME="$broken_home" PATH="$broken_bin:/usr/bin:/bin" \
    "$HARNESS" tool --host local --name git-lfs --plan \
    >"$TEMP_DIR/git-lfs-live-new-plan.out"
grep 'KEEP command=git-lfs source=host-provided' "$TEMP_DIR/git-lfs-live-new-plan.out" \
    >/dev/null || fail "Git LFS newer host retention"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "ShellCheck - shell script analysis tool" "version: 0.10.0"' \
    >"$broken_bin/shellcheck"
chmod 755 "$broken_bin/shellcheck"
HOME="$broken_home" PATH="$broken_bin:/usr/bin:/bin" \
    "$HARNESS" tool --host local --name shellcheck --plan \
    >"$TEMP_DIR/shellcheck-live-old-plan.out"
grep 'SHADOW command=shellcheck reason=host-command-unusable strategy=user-path' \
    "$TEMP_DIR/shellcheck-live-old-plan.out" >/dev/null ||
    fail "ShellCheck exact live version floor"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "ShellCheck - shell script analysis tool" "version: 0.11.0"' \
    >"$broken_bin/shellcheck"
HOME="$broken_home" PATH="$broken_bin:/usr/bin:/bin" \
    "$HARNESS" tool --host local --name shellcheck --plan \
    >"$TEMP_DIR/shellcheck-live-exact-plan.out"
grep 'KEEP command=shellcheck source=host-provided' \
    "$TEMP_DIR/shellcheck-live-exact-plan.out" >/dev/null ||
    fail "ShellCheck exact host retention"

mkdir -p "$TEMP_DIR/claude-plan-home"
HOME="$TEMP_DIR/claude-plan-home" "$HARNESS" tool --host al --name claude \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/claude-arm-plan.out"
grep 'INSTALL artifact=.*claude/2.1.207/linux-aarch64' \
    "$TEMP_DIR/claude-arm-plan.out" >/dev/null || fail "Claude AArch64 artifact plan"
grep 'sha256=02c381be3269489119287dc0b5f4b99b870d886f058918994b51e06b701dd1be' \
    "$TEMP_DIR/claude-arm-plan.out" >/dev/null || fail "Claude AArch64 checksum plan"
grep 'EXTRACT format=tar.gz member=package/claude binary=claude' \
    "$TEMP_DIR/claude-arm-plan.out" >/dev/null || fail "Claude extraction plan"

mkdir -p "$TEMP_DIR/tectonic-plan-home"
HOME="$TEMP_DIR/tectonic-plan-home" "$HARNESS" tool --host rc --name tectonic \
    --facts "$ROOT/tests/fixtures/rc.facts" --plan >"$TEMP_DIR/tectonic-x86-plan.out"
grep 'sha256=60b13a0826ae7ad9ce34b4a2df06bff2cfcfa6dda8a915477c0cbb84e1a4a902' \
    "$TEMP_DIR/tectonic-x86-plan.out" >/dev/null || fail "Tectonic x86-64 checksum plan"
HOME="$TEMP_DIR/tectonic-plan-home" "$HARNESS" tool --host al --name tectonic \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/tectonic-arm-plan.out"
grep 'sha256=f9aa39017dbd51f111fdb93dda222178cbe51c8193508fc567b523cc74fff9c1' \
    "$TEMP_DIR/tectonic-arm-plan.out" >/dev/null || fail "Tectonic AArch64 checksum plan"
grep 'EXTRACT format=tar.gz member=tectonic binary=tectonic' \
    "$TEMP_DIR/tectonic-arm-plan.out" >/dev/null || fail "Tectonic root-member plan"

mkdir -p "$TEMP_DIR/git-lfs-plan-home"
HOME="$TEMP_DIR/git-lfs-plan-home" "$HARNESS" tool --host ab --name git-lfs \
    --facts "$ROOT/tests/fixtures/ab.facts" --plan >"$TEMP_DIR/git-lfs-x86-plan.out"
grep 'sha256=1c0b6ee5200ca708c5cebebb18fdeb0e1c98f1af5c1a9cba205a4c0ab5a5ec08' \
    "$TEMP_DIR/git-lfs-x86-plan.out" >/dev/null || fail "Git LFS x86-64 checksum plan"
HOME="$TEMP_DIR/git-lfs-plan-home" "$HARNESS" tool --host al --name git-lfs \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/git-lfs-arm-plan.out"
grep 'sha256=73a9c90eeb4312133a63c3eaee0c38c019ea7bfa0953d174809d25b18588dd8d' \
    "$TEMP_DIR/git-lfs-arm-plan.out" >/dev/null || fail "Git LFS AArch64 checksum plan"
HOME="$TEMP_DIR/git-lfs-plan-home" "$HARNESS" tool --host ri --name git-lfs \
    --facts "$ROOT/tests/fixtures/ri.facts" --plan >"$TEMP_DIR/git-lfs-old-plan.out"
grep 'SHADOW command=git-lfs reason=host-command-unusable strategy=user-path' \
    "$TEMP_DIR/git-lfs-old-plan.out" >/dev/null || fail "Git LFS captured security floor"
HOME="$TEMP_DIR/git-lfs-plan-home" "$HARNESS" tool --host rc --name git-lfs \
    --facts "$ROOT/tests/fixtures/rc.facts" --plan >"$TEMP_DIR/git-lfs-current-plan.out"
grep 'KEEP command=git-lfs source=host-provided' "$TEMP_DIR/git-lfs-current-plan.out" \
    >/dev/null || fail "Git LFS captured current host retention"

mkdir -p "$TEMP_DIR/sqlite-plan-home"
HOME="$TEMP_DIR/sqlite-plan-home" "$HARNESS" build-tool --host al --name sqlite \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/sqlite-arm-plan.out"
grep 'BUILD artifact=.*sqlite/3.53.3/linux-aarch64' "$TEMP_DIR/sqlite-arm-plan.out" \
    >/dev/null || fail "SQLite AArch64 source-build plan"
grep 'sha256=646421e12aac110282ef8cc68f1a62d4bb15fc7b8f09da0b53e29ee690500431' \
    "$TEMP_DIR/sqlite-arm-plan.out" >/dev/null || fail "SQLite source checksum plan"
grep "COMPILE native='cc -O2 .* -o sqlite3'" "$TEMP_DIR/sqlite-arm-plan.out" \
    >/dev/null || fail "SQLite native compile plan"

mkdir -p "$TEMP_DIR/tree-plan-home"
HOME="$TEMP_DIR/tree-plan-home" "$HARNESS" build-tool --host t4 --name tree \
    --facts "$ROOT/tests/fixtures/t4.facts" --plan >"$TEMP_DIR/tree-plan.out"
grep 'BUILD artifact=.*tree/2.3.2/linux-x86_64' "$TEMP_DIR/tree-plan.out" \
    >/dev/null || fail "Tree source-build plan"
grep 'sha256=6b941dd6cbecfb4d3250700e4d08d8e0c251488981dd4868b90d744234300e21' \
    "$TEMP_DIR/tree-plan.out" >/dev/null || fail "Tree source checksum plan"
grep "COMPILE native='cc -O2 .* -o tree'" "$TEMP_DIR/tree-plan.out" \
    >/dev/null || fail "Tree native compile plan"

mkdir -p "$TEMP_DIR/tmux-plan-home"
HOME="$TEMP_DIR/tmux-plan-home" "$HARNESS" build-tool --host al --name tmux \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/tmux-plan.out"
grep 'BUILD artifact=.*tmux/3.6b/linux-aarch64' "$TEMP_DIR/tmux-plan.out" \
    >/dev/null || fail "tmux AArch64 source-build plan"
grep 'sha256=390759d25fdba016887ec982b808927e637070fd7d03a8021f8ef3102b9ae3c7' \
    "$TEMP_DIR/tmux-plan.out" >/dev/null || fail "tmux source checksum plan"
grep 'DEPENDENCY name=libevent version=2.1.12-stable entries=234 linkage=static' \
    "$TEMP_DIR/tmux-plan.out" >/dev/null || fail "tmux pinned dependency plan"
grep 'sha256=92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb' \
    "$TEMP_DIR/tmux-plan.out" >/dev/null || fail "libevent dependency checksum plan"

mkdir -p "$TEMP_DIR/htop-plan-home"
HOME="$TEMP_DIR/htop-plan-home" "$HARNESS" build-tool --host t4 --name htop \
    --facts "$ROOT/tests/fixtures/t4.facts" --plan >"$TEMP_DIR/htop-plan.out"
grep 'BUILD artifact=.*htop/3.5.1/linux-x86_64' "$TEMP_DIR/htop-plan.out" \
    >/dev/null || fail "htop x86-64 source-build plan"
grep 'sha256=526cecd62870aa8d14d2a79a35ea197e4e2b5317d275b567cee0574b2ddb2e9a' \
    "$TEMP_DIR/htop-plan.out" >/dev/null || fail "htop source checksum plan"
grep "COMPILE native='./configure --prefix=DEST --without-libunwind && make -j2'" \
    "$TEMP_DIR/htop-plan.out" >/dev/null || fail "htop native compile plan"

mkdir -p "$TEMP_DIR/runtime-plan-home"
HOME="$TEMP_DIR/runtime-plan-home" "$HARNESS" runtime --host al --name node \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/node-arm-plan.out"
grep 'sha256=589f5b6dd4fcfee4dfda73013903c966abaa8abd93dbc9d436544e472b4f0e74' \
    "$TEMP_DIR/node-arm-plan.out" >/dev/null || fail "Node AArch64 checksum plan"
grep 'CREATE link=.*\.local/bin/npm source=.*/bin/npm' \
    "$TEMP_DIR/node-arm-plan.out" >/dev/null || fail "Node npm activation plan"

mkdir -p "$TEMP_DIR/runtime-facts-home"
HOME="$TEMP_DIR/runtime-facts-home" "$HARNESS" runtime --host local --name node \
    --facts "$ROOT/tests/fixtures/local.facts" --plan \
    >"$TEMP_DIR/node-exact-facts-plan.out"
grep 'KEEP runtime=node source=host-provided' \
    "$TEMP_DIR/node-exact-facts-plan.out" >/dev/null || fail "exact captured Node retention"
sed -e 's/^tool_node_version=v24\.16\.0$/tool_node_version=v18.19.1/' \
    -e 's/^tool_npm_version=11\.13\.0$/tool_npm_version=9.2.0/' \
    "$ROOT/tests/fixtures/local.facts" >"$TEMP_DIR/node-old.facts"
HOME="$TEMP_DIR/runtime-facts-home" "$HARNESS" plan --host local \
    --facts "$TEMP_DIR/node-old.facts" >"$TEMP_DIR/node-old-aggregate-plan.out"
grep 'INSTALL tool=node command=node .*reason=host-command-version-mismatch observed=v18.19.1 required=v24.16.0' \
    "$TEMP_DIR/node-old-aggregate-plan.out" >/dev/null ||
    fail "old captured Node aggregate plan"
grep 'INSTALL tool=npm command=npm .*reason=host-command-version-mismatch observed=9.2.0 required=11.13.0' \
    "$TEMP_DIR/node-old-aggregate-plan.out" >/dev/null ||
    fail "old captured npm aggregate plan"
HOME="$TEMP_DIR/runtime-facts-home" "$HARNESS" runtime --host local --name node \
    --facts "$TEMP_DIR/node-old.facts" --plan \
    >"$TEMP_DIR/node-old-facts-plan.out"
grep 'SHADOW runtime=node reason=host-runtime-version-mismatch strategy=user-path' \
    "$TEMP_DIR/node-old-facts-plan.out" >/dev/null || fail "old captured Node shadow plan"

runtime_old_bin=$TEMP_DIR/runtime-old-bin
runtime_old_home=$TEMP_DIR/runtime-old-home
mkdir -p "$runtime_old_bin" "$runtime_old_home"
printf '%s\n' '#!/bin/sh' 'echo v18.19.1' >"$runtime_old_bin/node"
printf '%s\n' '#!/bin/sh' 'echo 9.2.0' >"$runtime_old_bin/npm"
chmod 755 "$runtime_old_bin/node" "$runtime_old_bin/npm"
HOME="$runtime_old_home" PATH="$runtime_old_bin:/usr/bin:/bin" \
    "$HARNESS" runtime --host local --name node --plan \
    >"$TEMP_DIR/node-old-host-plan.out"
grep 'SHADOW runtime=node reason=host-runtime-version-mismatch strategy=user-path' \
    "$TEMP_DIR/node-old-host-plan.out" >/dev/null || fail "old host Node shadow plan"
grep 'INSTALL runtime_tree=.*node/24.16.0/linux-x86_64' \
    "$TEMP_DIR/node-old-host-plan.out" >/dev/null || fail "old host Node install plan"

runtime_exact_bin=$TEMP_DIR/runtime-exact-bin
runtime_exact_home=$TEMP_DIR/runtime-exact-home
mkdir -p "$runtime_exact_bin" "$runtime_exact_home"
printf '%s\n' '#!/bin/sh' 'echo v24.16.0' >"$runtime_exact_bin/node"
printf '%s\n' '#!/bin/sh' 'echo 11.13.0' >"$runtime_exact_bin/npm"
chmod 755 "$runtime_exact_bin/node" "$runtime_exact_bin/npm"
HOME="$runtime_exact_home" PATH="$runtime_exact_bin:/usr/bin:/bin" \
    "$HARNESS" runtime --host local --name node --plan \
    >"$TEMP_DIR/node-exact-host-plan.out"
grep 'KEEP runtime=node source=host-provided' \
    "$TEMP_DIR/node-exact-host-plan.out" >/dev/null || fail "exact host Node retention"

path_home=$TEMP_DIR/path-home
mkdir -p "$path_home/.local/bin"
printf '%s\n' '#!/bin/sh' 'exit 0' >"$path_home/.local/bin/rg"
chmod 755 "$path_home/.local/bin/rg"
HOME="$path_home" PATH="/usr/bin:/bin" "$HARNESS" inventory --host local \
    >"$TEMP_DIR/user-bin-inventory.out"
grep '^tool_rg=present$' "$TEMP_DIR/user-bin-inventory.out" >/dev/null ||
    fail "inventory missed user tool outside inherited PATH"

# Exercise a real apply/rollback against an isolated clean Git checkout.
test_repo=$TEMP_DIR/repo
test_home=$TEMP_DIR/home
mkdir -p "$test_repo" "$test_home"
managed_rg_dir=$test_home/.local/opt/ripgrep/15.1.0/linux-x86_64
mkdir -p "$managed_rg_dir" "$test_home/.local/bin"
printf '%s\n' '#!/bin/sh' 'echo "ripgrep 15.1.0"' >"$managed_rg_dir/rg"
chmod 755 "$managed_rg_dir/rg"
ln -s "$managed_rg_dir/rg" "$test_home/.local/bin/rg"
HOME="$test_home" PATH="/usr/bin:/bin" \
    "$HARNESS" tool --host local --name ripgrep --plan \
    >"$TEMP_DIR/managed-tool-plan.out"
grep 'KEEP command=rg source=managed-artifact' "$TEMP_DIR/managed-tool-plan.out" \
    >/dev/null || fail "managed tool discovery outside PATH"
rm "$test_home/.local/bin/rg" "$managed_rg_dir/rg"
rmdir "$managed_rg_dir"
managed_ninja_dir=$test_home/.local/opt/ninja/1.13.2/linux-x86_64
mkdir -p "$managed_ninja_dir"
printf '%s\n' '#!/bin/sh' 'echo 0.0' >"$managed_ninja_dir/ninja"
chmod 755 "$managed_ninja_dir/ninja"
ln -s "$managed_ninja_dir/ninja" "$test_home/.local/bin/ninja"
if HOME="$test_home" PATH="/usr/bin:/bin" \
    "$HARNESS" tool --host local --name ninja --plan \
    >"$TEMP_DIR/invalid-managed-ninja.out" 2>&1; then
    fail "tool plan accepted an invalid managed Ninja"
fi
grep 'BLOCK command=ninja reason=managed-artifact-version-or-health-mismatch' \
    "$TEMP_DIR/invalid-managed-ninja.out" >/dev/null || fail "invalid managed Ninja evidence"
rm "$test_home/.local/bin/ninja" "$managed_ninja_dir/ninja"
rmdir "$managed_ninja_dir"
cp -R "$ROOT/bin" "$ROOT/config" "$ROOT/libexec" "$ROOT/profiles" "$ROOT/shared" \
    "$ROOT/shell" "$ROOT/tools" "$ROOT/.codex" "$ROOT/.claude" "$test_repo/"
site_command_bin=$TEMP_DIR/site-command-bin
mkdir -p "$site_command_bin"
for command_name in qsub qstat qdel nodestatus; do
    printf '%s\n' '#!/bin/sh' 'exit 0' >"$site_command_bin/$command_name"
    chmod 755 "$site_command_bin/$command_name"
done
sed -i "s|^command_paths=.*$|command_paths=$site_command_bin|" \
    "$test_repo/profiles/hosts/ab.conf"
HOME="$test_home" PATH="/usr/bin:/bin" "$test_repo/bin/harness" \
    inventory --host ab >"$TEMP_DIR/site-command-inventory.out"
for command_name in qsub qstat qdel nodestatus; do
    grep "^tool_${command_name}=present$" "$TEMP_DIR/site-command-inventory.out" \
        >/dev/null || fail "profile site-command discovery: $command_name"
done
zip_fixture_dir=$TEMP_DIR/zip-fixture
zip_fixture_archive=$TEMP_DIR/rclone-fixture.zip
zip_fixture_member=rclone-v1.74.3-linux-amd64/rclone
mkdir -p "$zip_fixture_dir"
printf '%s\n' '#!/bin/sh' 'echo "rclone v1.74.3"' >"$zip_fixture_dir/rclone"
chmod 755 "$zip_fixture_dir/rclone"
python3 -c 'import sys,zipfile; z=zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED); z.write(sys.argv[2], sys.argv[3]); z.close()' \
    "$zip_fixture_archive" "$zip_fixture_dir/rclone" "$zip_fixture_member"
zip_fixture_hash=$(sha256sum "$zip_fixture_archive" | awk '{print $1}')
sed -i "s/dbee7ccd7a5d617e4ed4cd4555c16669b511abfe8d31164f61be35ac9e999bd2/$zip_fixture_hash/" \
    "$test_repo/tools/artifacts.tsv"
restic_fixture=$TEMP_DIR/restic-fixture
printf '%s\n' '#!/bin/sh' '[ "${1:-}" = version ] || exit 2' \
    'echo "restic 0.19.1 compiled with go1.26.0 on linux/amd64"' \
    >"$restic_fixture.binary"
chmod 755 "$restic_fixture.binary"
bzip2 -c "$restic_fixture.binary" >"$restic_fixture.bz2"
restic_fixture_hash=$(sha256sum "$restic_fixture.bz2" | awk '{print $1}')
sed -i "s/f415415624dcc452f2a02b8c33641791a8c6d6d3b65bbb3543fcf9a25151585c/$restic_fixture_hash/" \
    "$test_repo/tools/artifacts.tsv"
tectonic_fixture_dir=$TEMP_DIR/tectonic-fixture
tectonic_fixture_archive=$TEMP_DIR/tectonic-fixture.tar.gz
mkdir -p "$tectonic_fixture_dir"
printf '%s\n' '#!/bin/sh' 'echo "Tectonic 0.16.9"' >"$tectonic_fixture_dir/tectonic"
chmod 755 "$tectonic_fixture_dir/tectonic"
tar -czf "$tectonic_fixture_archive" -C "$tectonic_fixture_dir" tectonic
tectonic_fixture_hash=$(sha256sum "$tectonic_fixture_archive" | awk '{print $1}')
sed -i "s/60b13a0826ae7ad9ce34b4a2df06bff2cfcfa6dda8a915477c0cbb84e1a4a902/$tectonic_fixture_hash/" \
    "$test_repo/tools/artifacts.tsv"
shellcheck_fixture_dir=$TEMP_DIR/shellcheck-fixture/shellcheck-v0.11.0
shellcheck_fixture_archive=$TEMP_DIR/shellcheck-fixture.tar.gz
mkdir -p "$shellcheck_fixture_dir"
printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "ShellCheck - shell script analysis tool" "version: 0.11.0" "license: GNU General Public License, version 3"' \
    >"$shellcheck_fixture_dir/shellcheck"
chmod 755 "$shellcheck_fixture_dir/shellcheck"
tar -czf "$shellcheck_fixture_archive" -C "$TEMP_DIR/shellcheck-fixture" \
    shellcheck-v0.11.0/shellcheck
shellcheck_fixture_hash=$(sha256sum "$shellcheck_fixture_archive" | awk '{print $1}')
sed -i "s/b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6/$shellcheck_fixture_hash/" \
    "$test_repo/tools/artifacts.tsv"
sqlite_fixture_dir=$TEMP_DIR/sqlite-fixture
sqlite_fixture_root=$sqlite_fixture_dir/sqlite-amalgamation-3530300
sqlite_fixture_archive=$TEMP_DIR/sqlite-fixture.zip
mkdir -p "$sqlite_fixture_root"
printf '%s\n' \
    '#include <stdio.h>' \
    '#include <string.h>' \
    'int main(int argc, char **argv) {' \
    '  if (argc > 1 && strcmp(argv[1], "--version") == 0) {' \
    '    puts("3.53.3 fixture"); return 0;' \
    '  }' \
    '  puts("1"); puts("1"); return 0;' \
    '}' >"$sqlite_fixture_root/shell.c"
printf '%s\n' '/* fixture translation unit */' >"$sqlite_fixture_root/sqlite3.c"
printf '%s\n' '/* fixture header */' >"$sqlite_fixture_root/sqlite3.h"
printf '%s\n' '/* fixture extension header */' >"$sqlite_fixture_root/sqlite3ext.h"
python3 - "$sqlite_fixture_dir" "$sqlite_fixture_archive" <<'PY'
import pathlib, sys, zipfile
base, output = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
root = base / "sqlite-amalgamation-3530300"
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    archive.writestr("sqlite-amalgamation-3530300/", "")
    for name in ("sqlite3.c", "shell.c", "sqlite3.h", "sqlite3ext.h"):
        archive.write(root / name, f"sqlite-amalgamation-3530300/{name}")
PY
sqlite_fixture_hash=$(sha256sum "$sqlite_fixture_archive" | awk '{print $1}')
sed -i "s/646421e12aac110282ef8cc68f1a62d4bb15fc7b8f09da0b53e29ee690500431/$sqlite_fixture_hash/" \
    "$test_repo/tools/sources.tsv"
tree_fixture_dir=$TEMP_DIR/tree-fixture
tree_fixture_root=$tree_fixture_dir/tree-2.3.2
tree_fixture_archive=$TEMP_DIR/tree-fixture.tar.gz
mkdir -p "$tree_fixture_root/doc"
printf '%s\n' \
    '#include <stdio.h>' \
    '#include <string.h>' \
    'int main(int argc, char **argv) {' \
    '  if (argc > 1 && strcmp(argv[1], "--version") == 0) {' \
    '    puts("tree v2.3.2 fixture"); return 0;' \
    '  }' \
    '  puts("fixture"); return 0;' \
    '}' >"$tree_fixture_root/tree.c"
for source_file in color.c file.c filter.c hash.c html.c info.c json.c list.c \
    strverscmp.c unix.c util.c xml.c; do
    printf '%s\n' '/* fixture translation unit */' >"$tree_fixture_root/$source_file"
done
for fixture_file in CHANGES INSTALL LICENSE Makefile README TODO tree.h .gitignore \
    doc/tree.1 doc/xml.dtd doc/global_info; do
    printf '%s\n' fixture >"$tree_fixture_root/$fixture_file"
done
tar -czf "$tree_fixture_archive" -C "$tree_fixture_dir" \
    tree-2.3.2/CHANGES tree-2.3.2/INSTALL tree-2.3.2/LICENSE \
    tree-2.3.2/Makefile tree-2.3.2/README tree-2.3.2/TODO \
    tree-2.3.2/color.c tree-2.3.2/file.c tree-2.3.2/filter.c \
    tree-2.3.2/hash.c tree-2.3.2/html.c tree-2.3.2/info.c \
    tree-2.3.2/json.c tree-2.3.2/list.c tree-2.3.2/strverscmp.c \
    tree-2.3.2/tree.c tree-2.3.2/tree.h tree-2.3.2/unix.c \
    tree-2.3.2/util.c tree-2.3.2/xml.c tree-2.3.2/doc/tree.1 \
    tree-2.3.2/doc/xml.dtd tree-2.3.2/doc/global_info tree-2.3.2/.gitignore
tree_fixture_hash=$(sha256sum "$tree_fixture_archive" | awk '{print $1}')
sed -i "s/6b941dd6cbecfb4d3250700e4d08d8e0c251488981dd4868b90d744234300e21/$tree_fixture_hash/" \
    "$test_repo/tools/sources.tsv"
runtime_fixture_parent=$TEMP_DIR/runtime-fixture
runtime_fixture_root=$runtime_fixture_parent/node-v24.16.0-linux-x64
runtime_fixture_archive=$TEMP_DIR/node-fixture.tar.gz
mkdir -p "$runtime_fixture_root/bin" "$runtime_fixture_root/lib"
printf '%s\n' '#!/bin/sh' 'echo v24.16.0' >"$runtime_fixture_root/bin/node"
printf '%s\n' '#!/bin/sh' 'echo 11.13.0' >"$runtime_fixture_root/lib/npm.sh"
chmod 755 "$runtime_fixture_root/bin/node" "$runtime_fixture_root/lib/npm.sh"
for command_name in npm npx corepack; do
    ln -s ../lib/npm.sh "$runtime_fixture_root/bin/$command_name"
done
tar -czf "$runtime_fixture_archive" -C "$runtime_fixture_parent" \
    node-v24.16.0-linux-x64
runtime_fixture_hash=$(sha256sum "$runtime_fixture_archive" | awk '{print $1}')
sed -i "s/2faf6a387e9b62b888e21c54f01249fb27537ffecf1842f29f4c919d0a59a0ff/$runtime_fixture_hash/" \
    "$test_repo/tools/runtimes.tsv"
agent_launcher_parent=$TEMP_DIR/agent-launcher-fixture
agent_launcher_root=$agent_launcher_parent/package
agent_launcher_archive=$TEMP_DIR/codex-launcher-fixture.tar.gz
mkdir -p "$agent_launcher_root/bin"
printf '%s\n' '#!/bin/sh' 'echo "codex-cli 0.144.4"' >"$agent_launcher_root/bin/codex.js"
chmod 755 "$agent_launcher_root/bin/codex.js"
printf '%s\n' '{"name":"@openai/codex","version":"0.144.4"}' \
    >"$agent_launcher_root/package.json"
tar -czf "$agent_launcher_archive" -C "$agent_launcher_parent" package
agent_launcher_hash=$(sha256sum "$agent_launcher_archive" | awk '{print $1}')
agent_native_parent=$TEMP_DIR/agent-native-fixture
agent_native_root=$agent_native_parent/package
agent_native_archive=$TEMP_DIR/codex-native-fixture.tar.gz
mkdir -p "$agent_native_root/vendor/x86_64-unknown-linux-musl/bin"
printf '%s\n' native-fixture >"$agent_native_root/vendor/x86_64-unknown-linux-musl/bin/codex"
printf '%s\n' '{"name":"@openai/codex","version":"0.144.4-linux-x64"}' \
    >"$agent_native_root/package.json"
tar -czf "$agent_native_archive" -C "$agent_native_parent" package
agent_native_hash=$(sha256sum "$agent_native_archive" | awk '{print $1}')
sed -i "s/613aadb30be4b6a6daa45cbd086f5d4a84636bcd8c036510c106464bd087f193/$agent_launcher_hash/g" \
    "$test_repo/tools/agents.tsv"
sed -i "s/9a4a45314e80b53c4761b80067e3a68c2302f9a9026059b5f54f22dec8f34323/$agent_native_hash/" \
    "$test_repo/tools/agents.tsv"
git -C "$test_repo" init -q
git -C "$test_repo" config user.name harness-test
git -C "$test_repo" config user.email harness-test.invalid
git -C "$test_repo" add .
git -C "$test_repo" commit -qm baseline

# A managed command link must preserve a valid lexical checkout path. Some HPC
# homes have node-dependent canonical mount aliases, so readlink -f can name a
# different but equivalent checkout and falsely block every managed link.
alias_repo=$TEMP_DIR/repo-alias
alias_home=$TEMP_DIR/alias-home
mkdir -p "$alias_home"
ln -s "$test_repo" "$alias_repo"
HOME="$alias_home" "$alias_repo/bin/harness" apply --host local --apply \
    >"$TEMP_DIR/alias-apply.out"
alias_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/alias-apply.out")
[ -n "$alias_transaction" ] || fail "missing aliased checkout transaction"
HOME="$alias_home" "$alias_home/.local/bin/harness" apply --host local --plan \
    >"$TEMP_DIR/alias-plan.out"
if grep '^BLOCK ' "$TEMP_DIR/alias-plan.out" >/dev/null 2>&1; then
    fail "managed command canonicalized an equivalent checkout alias"
fi
grep "KEEP link=$alias_home/.local/bin/harness" "$TEMP_DIR/alias-plan.out" \
    >/dev/null || fail "managed command lost lexical checkout root"
HOME="$alias_home" "$alias_repo/bin/harness" rollback "$alias_transaction" \
    >"$TEMP_DIR/alias-rollback.out"

HOME="$test_home" "$test_repo/bin/harness" apply --host local --plan \
    >"$TEMP_DIR/control-plan.out"
grep 'changes=not-applied' "$TEMP_DIR/control-plan.out" >/dev/null ||
    fail "control-plane dry run"
HOME="$test_home" "$test_repo/bin/harness" apply --host local --apply \
    >"$TEMP_DIR/control-apply.out"
transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/control-apply.out")
[ -n "$transaction" ] || fail "missing apply transaction"
[ -L "$test_home/.local/bin/harness" ] || fail "missing applied command link"
[ -L "$test_home/.codex/AGENTS.md" ] || fail "missing applied guidance link"
[ "$(readlink "$test_home/.codex/AGENTS.md")" = \
    "$test_repo/.codex/AGENTS.md" ] || fail "wrong applied Codex guidance target"
[ -L "$test_home/.claude/CLAUDE.md" ] || fail "missing applied Claude guidance link"
[ "$(readlink "$test_home/.claude/CLAUDE.md")" = \
    "$test_repo/.claude/CLAUDE.md" ] || fail "wrong applied Claude guidance target"
cmp -s "$test_home/.claude/CLAUDE.md" "$test_repo/.codex/AGENTS.md" ||
    fail "applied Claude guidance differs from canonical policy"
for skill_path in "$test_repo"/shared/skills/*; do
    [ -f "$skill_path/SKILL.md" ] || continue
    skill_name=${skill_path##*/}
    for skill_link in \
        "$test_home/.codex/skills/$skill_name" \
        "$test_home/.agents/skills/$skill_name" \
        "$test_home/.claude/skills/$skill_name"; do
        [ -L "$skill_link" ] && [ "$(readlink "$skill_link")" = "$skill_path" ] ||
            fail "missing or incorrect applied skill link: $skill_link"
    done
done
rm "$test_home/.local/bin/harness"
ln -s "$TEMP_DIR/foreign" "$test_home/.local/bin/harness"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$transaction" \
    >"$TEMP_DIR/refused-rollback.out" 2>&1; then
    fail "rollback removed a changed link"
fi
[ "$(readlink "$test_home/.local/bin/harness")" = "$TEMP_DIR/foreign" ] ||
    fail "rollback did not preserve a changed link"
rm "$test_home/.local/bin/harness"
ln -s "$test_repo/bin/harness" "$test_home/.local/bin/harness"
HOME="$test_home" "$test_repo/bin/harness" rollback "$transaction" \
    >"$TEMP_DIR/control-rollback.out"
[ ! -L "$test_home/.local/bin/harness" ] || fail "rollback left command link"
[ ! -L "$test_home/.codex/AGENTS.md" ] || fail "rollback left guidance link"
[ ! -L "$test_home/.claude/CLAUDE.md" ] ||
    fail "rollback left Claude guidance link"
for skill_path in "$test_repo"/shared/skills/*; do
    [ -f "$skill_path/SKILL.md" ] || continue
    skill_name=${skill_path##*/}
    for skill_link in \
        "$test_home/.codex/skills/$skill_name" \
        "$test_home/.agents/skills/$skill_name" \
        "$test_home/.claude/skills/$skill_name"; do
        [ ! -L "$skill_link" ] || fail "rollback left skill link: $skill_link"
    done
done
grep 'status=rolled-back' "$TEMP_DIR/control-rollback.out" >/dev/null ||
    fail "rollback transaction status"

printf '%s\n' 'export TEST_TOKEN=fake-secret-value' >"$test_home/.bashrc"
printf '%s\n' '# existing login setup' >"$test_home/.bash_profile"
cp "$test_home/.bashrc" "$TEMP_DIR/original-bashrc"
cp "$test_home/.bash_profile" "$TEMP_DIR/original-bash-profile"
HOME="$test_home" "$test_repo/bin/harness" shell --host local --plan \
    >"$TEMP_DIR/shell-plan.out"
grep 'APPEND file=.bashrc' "$TEMP_DIR/shell-plan.out" >/dev/null || fail "shell plan"
HOME="$test_home" "$test_repo/bin/harness" shell --host local --apply \
    >"$TEMP_DIR/shell-apply.out"
shell_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' "$TEMP_DIR/shell-apply.out")
[ -n "$shell_transaction" ] || fail "missing shell transaction"
if grep -R 'fake-secret-value' "$test_home/.local/state/harness" >/dev/null 2>&1; then
    fail "shell transaction copied pre-existing content"
fi
applied_size=$(wc -c <"$test_home/.bashrc" | tr -d ' ')
printf '%s\n' '# later user change' >>"$test_home/.bashrc"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$shell_transaction" \
    >"$TEMP_DIR/refused-shell-rollback.out" 2>&1; then
    fail "shell rollback accepted later changes"
fi
grep 'later user change' "$test_home/.bashrc" >/dev/null ||
    fail "shell rollback damaged later changes"
truncate -s "$applied_size" "$test_home/.bashrc"
HOME="$test_home" "$test_repo/bin/harness" rollback "$shell_transaction" \
    >"$TEMP_DIR/shell-rollback.out"
cmp -s "$test_home/.bashrc" "$TEMP_DIR/original-bashrc" || fail "bashrc rollback"
cmp -s "$test_home/.bash_profile" "$TEMP_DIR/original-bash-profile" || fail "bash profile rollback"

# Early cache bootstrapping prepends only a public managed payload. It must not
# copy existing startup content, must precede owner commands, and must be
# removable while preserving later owner edits.
cache_home=$TEMP_DIR/cache-bootstrap-home
mkdir -p "$cache_home"
printf '%s\n' \
    'export TEST_TOKEN=fake-secret-value' \
    'printf "%s\\n" "${XDG_CACHE_HOME:-unset}" >"$HOME/bashrc-observed"' \
    >"$cache_home/.bashrc"
printf '%s\n' \
    'printf "%s\\n" "${XDG_CACHE_HOME:-unset}" >"$HOME/login-observed"' \
    >"$cache_home/.bash_profile"
HOME="$cache_home" "$test_repo/bin/harness" shell --host local --apply \
    >"$TEMP_DIR/cache-shell-apply.out"
ln -s "$test_repo" "$cache_home/harness"
HOME="$cache_home" "$test_repo/bin/harness" cache-bootstrap --host local --plan \
    >"$TEMP_DIR/cache-bootstrap-plan.out"
[ "$(grep -c '^PREPEND file=' "$TEMP_DIR/cache-bootstrap-plan.out")" -eq 2 ] ||
    fail "cache bootstrap plan did not cover both startup files"
HOME="$cache_home" "$test_repo/bin/harness" cache-bootstrap --host local --apply \
    >"$TEMP_DIR/cache-bootstrap-apply.out"
cache_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/cache-bootstrap-apply.out")
[ -n "$cache_transaction" ] || fail "missing cache bootstrap transaction"
HOME="$cache_home" "$test_repo/bin/harness" cache-bootstrap --host local --plan \
    >"$TEMP_DIR/cache-bootstrap-idempotent.out"
[ "$(grep -c '^KEEP file=' "$TEMP_DIR/cache-bootstrap-idempotent.out")" -eq 2 ] ||
    fail "cache bootstrap is not idempotent"
for startup in .bashrc .bash_profile; do
    [ "$(sed -n '1p' "$cache_home/$startup")" = '# >>> harness early managed >>>' ] ||
        fail "cache bootstrap is not the first startup block: $startup"
done
if grep -R 'fake-secret-value' "$cache_home/.local/state/harness" >/dev/null 2>&1; then
    fail "cache bootstrap copied pre-existing startup content"
fi
HOME="$cache_home" PATH=/usr/bin:/bin sh "$cache_home/.bash_profile" \
    >"$TEMP_DIR/cache-login-output.out" 2>&1 || fail "cache bootstrap login execution"
HOME="$cache_home" PATH=/usr/bin:/bin sh "$cache_home/.bashrc" \
    >"$TEMP_DIR/cache-bashrc-output.out" 2>&1 || fail "cache bootstrap bashrc execution"
[ ! -s "$TEMP_DIR/cache-login-output.out" ] && [ ! -s "$TEMP_DIR/cache-bashrc-output.out" ] ||
    fail "cache bootstrap startup was not silent"
expected_cache=/mnt/nfs-03/fast/Users/rioyokota/home-cache/xdg
[ "$(cat "$cache_home/login-observed")" = "$expected_cache" ] ||
    fail "login owner command ran before cache bootstrap"
[ "$(cat "$cache_home/bashrc-observed")" = "$expected_cache" ] ||
    fail "bashrc owner command ran before cache bootstrap"
[ ! -e "$cache_home/.cache" ] || fail "cache bootstrap created a default cache directory"
sed -i 's/^HARNESS_LOGICAL_HOST=local$/HARNESS_LOGICAL_HOST=changed/' \
    "$cache_home/.bashrc"
if HOME="$cache_home" "$test_repo/bin/harness" rollback "$cache_transaction" \
    >"$TEMP_DIR/cache-bootstrap-refused-rollback.out" 2>&1; then
    fail "cache bootstrap rollback accepted a changed prefix"
fi
grep -F -x 'HARNESS_LOGICAL_HOST=changed' "$cache_home/.bashrc" >/dev/null ||
    fail "refused cache rollback damaged the changed prefix"
grep -F '# >>> harness early managed >>>' "$cache_home/.bash_profile" >/dev/null ||
    fail "cache rollback mutated another file before validation completed"
sed -i 's/^HARNESS_LOGICAL_HOST=changed$/HARNESS_LOGICAL_HOST=local/' \
    "$cache_home/.bashrc"
printf '%s\n' '# later owner change' >>"$cache_home/.bashrc"
printf '%s\n' '# later owner change' >>"$cache_home/.bash_profile"
HOME="$cache_home" "$test_repo/bin/harness" rollback "$cache_transaction" \
    >"$TEMP_DIR/cache-bootstrap-rollback.out"
for startup in .bashrc .bash_profile; do
    if grep -F '# >>> harness early managed >>>' "$cache_home/$startup" >/dev/null; then
        fail "cache bootstrap rollback left an early marker: $startup"
    fi
    grep -F -x '# later owner change' "$cache_home/$startup" >/dev/null ||
        fail "cache bootstrap rollback lost a later owner edit: $startup"
    grep -F '# >>> harness managed >>>' "$cache_home/$startup" >/dev/null ||
        fail "cache bootstrap rollback damaged the managed suffix: $startup"
done
grep -F -x 'export TEST_TOKEN=fake-secret-value' "$cache_home/.bashrc" >/dev/null ||
    fail "cache bootstrap rollback damaged pre-existing startup content"

printf '%s\n' 'uenv start prgenv-gnu/25.11:v1 --view=default' >>"$test_home/.bashrc"
cp "$test_home/.bashrc" "$TEMP_DIR/original-remediation-bashrc"
HOME="$test_home" "$test_repo/bin/harness" remediate --host al --plan \
    >"$TEMP_DIR/remediation-plan.out"
grep 'PATCH file=.bashrc match=reviewed-uenv-start' \
    "$TEMP_DIR/remediation-plan.out" >/dev/null || fail "remediation plan"
HOME="$test_home" "$test_repo/bin/harness" remediate --host al --apply \
    >"$TEMP_DIR/remediation-apply.out"
remediation_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/remediation-apply.out")
[ -n "$remediation_transaction" ] || fail "missing remediation transaction"
grep -F -x '# harness: use prgenv for an interactive uenv' \
    "$test_home/.bashrc" >/dev/null || fail "remediation exact patch"
if grep -R 'fake-secret-value' "$test_home/.local/state/harness" >/dev/null 2>&1; then
    fail "remediation transaction copied pre-existing content"
fi
sed -i 's/^# harness: use prgenv/# xarness: use prgenv/' "$test_home/.bashrc"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$remediation_transaction" \
    >"$TEMP_DIR/refused-remediation-rollback.out" 2>&1; then
    fail "remediation rollback accepted a changed patch"
fi
grep -F -x '# xarness: use prgenv for an interactive uenv' \
    "$test_home/.bashrc" >/dev/null || fail "remediation rollback damaged changed patch"
sed -i 's/^# xarness: use prgenv/# harness: use prgenv/' "$test_home/.bashrc"
HOME="$test_home" "$test_repo/bin/harness" rollback "$remediation_transaction" \
    >"$TEMP_DIR/remediation-rollback.out"
cmp -s "$test_home/.bashrc" "$TEMP_DIR/original-remediation-bashrc" ||
    fail "remediation rollback"

ab2_remediation_home=$TEMP_DIR/ab2-remediation-home
mkdir -p "$ab2_remediation_home"
cat >"$ab2_remediation_home/.bash_profile" <<'EOF'
export TEST_TOKEN=fake-secret-value
# PyEnv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# later owner line
EOF
cp "$ab2_remediation_home/.bash_profile" "$TEMP_DIR/original-ab2-remediation-profile"
HOME="$ab2_remediation_home" "$test_repo/bin/harness" remediate --host ab2 --plan \
    >"$TEMP_DIR/ab2-remediation-plan.out"
grep 'PATCH file=.bash_profile match=reviewed-pyenv-block' \
    "$TEMP_DIR/ab2-remediation-plan.out" >/dev/null || fail "AB2 remediation plan"
HOME="$ab2_remediation_home" "$test_repo/bin/harness" remediate --host ab2 --apply \
    >"$TEMP_DIR/ab2-remediation-apply.out"
ab2_remediation_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/ab2-remediation-apply.out")
[ -n "$ab2_remediation_transaction" ] || fail "missing AB2 remediation transaction"
if grep -F 'pyenv' "$ab2_remediation_home/.bash_profile" >/dev/null; then
    fail "AB2 remediation left an obsolete pyenv call"
fi
grep -F -x 'export TEST_TOKEN=fake-secret-value' \
    "$ab2_remediation_home/.bash_profile" >/dev/null || fail "AB2 remediation damaged preceding owner content"
grep -F -x '# later owner line' "$ab2_remediation_home/.bash_profile" >/dev/null ||
    fail "AB2 remediation damaged following owner content"
if grep -R 'fake-secret-value' "$ab2_remediation_home/.local/state/harness" >/dev/null 2>&1; then
    fail "AB2 remediation copied unrelated startup content"
fi
HOME="$ab2_remediation_home" "$test_repo/bin/harness" remediate --host ab2 --plan \
    >"$TEMP_DIR/ab2-remediation-idempotent.out"
grep 'KEEP file=.bash_profile patch=reviewed-pyenv-block-disabled' \
    "$TEMP_DIR/ab2-remediation-idempotent.out" >/dev/null || fail "AB2 remediation idempotence"
sed -i 's/^# off  $/# xff  /' "$ab2_remediation_home/.bash_profile"
if HOME="$ab2_remediation_home" "$test_repo/bin/harness" rollback \
    "$ab2_remediation_transaction" >"$TEMP_DIR/refused-ab2-remediation.out" 2>&1; then
    fail "AB2 remediation rollback accepted a changed patch"
fi
sed -i 's/^# xff  $/# off  /' "$ab2_remediation_home/.bash_profile"
HOME="$ab2_remediation_home" "$test_repo/bin/harness" rollback \
    "$ab2_remediation_transaction" >"$TEMP_DIR/ab2-remediation-rollback.out"
cmp -s "$ab2_remediation_home/.bash_profile" \
    "$TEMP_DIR/original-ab2-remediation-profile" || fail "AB2 remediation rollback"

bash_common_home=$TEMP_DIR/bash-common-remediation-home
mkdir -p "$bash_common_home"
cat >"$bash_common_home/.bashrc" <<'EOF'
export TEST_TOKEN=fake-secret-value
# Source .bash_common
if [ -f "$HOME/.bash_common" ]; then
. "$HOME/.bash_common"
fi
# later owner line
EOF
printf '%s\n' 'retained until separately exact-unlinked' >"$bash_common_home/.bash_common"
chmod 640 "$bash_common_home/.bashrc"
HOME="$bash_common_home" "$test_repo/bin/harness" remediate --host ab \
    --remove-bash-common-reference --plan >"$TEMP_DIR/bash-common-plan.out"
grep 'REMOVE-BLOCK file=.bashrc match=reviewed-bash-common-reference kind=home-quoted lines=4' \
    "$TEMP_DIR/bash-common-plan.out" >/dev/null || fail "bash-common remediation plan"
HOME="$bash_common_home" "$test_repo/bin/harness" remediate --host ab \
    --remove-bash-common-reference --apply >"$TEMP_DIR/bash-common-apply.out"
grep 'REMEDIATION_APPLIED host=ab file=.bashrc removed=reviewed-bash-common-reference' \
    "$TEMP_DIR/bash-common-apply.out" >/dev/null || fail "bash-common remediation apply"
if grep -F '.bash_common' "$bash_common_home/.bashrc" >/dev/null; then
    fail "bash-common remediation retained a reference"
fi
grep -F -x 'export TEST_TOKEN=fake-secret-value' "$bash_common_home/.bashrc" >/dev/null ||
    fail "bash-common remediation damaged preceding owner content"
grep -F -x '# later owner line' "$bash_common_home/.bashrc" >/dev/null ||
    fail "bash-common remediation damaged following owner content"
[ "$(stat -c %a "$bash_common_home/.bashrc")" = 640 ] ||
    fail "bash-common remediation changed file mode"
[ -f "$bash_common_home/.bash_common" ] ||
    fail "bash-common reference remediation removed the separately managed file"
for path in "$bash_common_home"/.bashrc.harness-remediate.*; do
    [ ! -e "$path" ] && [ ! -L "$path" ] || fail "bash-common remediation left a temporary file"
done
HOME="$bash_common_home" "$test_repo/bin/harness" remediate --host ab \
    --remove-bash-common-reference --plan >"$TEMP_DIR/bash-common-idempotent.out"
grep 'KEEP file=.bashrc reference=.bash_common-absent' \
    "$TEMP_DIR/bash-common-idempotent.out" >/dev/null || fail "bash-common remediation idempotence"

bash_common_tilde_home=$TEMP_DIR/bash-common-remediation-tilde-home
mkdir -p "$bash_common_tilde_home"
cat >"$bash_common_tilde_home/.bashrc" <<'EOF'
# preceding owner line
# Source .bash_common
if [ -f ~/.bash_common ]; then
  . ~/.bash_common
fi
export AFTER_BLOCK=retained
EOF
HOME="$bash_common_tilde_home" "$test_repo/bin/harness" remediate --host rc \
    --remove-bash-common-reference --apply >"$TEMP_DIR/bash-common-tilde-apply.out"
grep 'REMEDIATION_APPLIED host=rc file=.bashrc removed=reviewed-bash-common-reference' \
    "$TEMP_DIR/bash-common-tilde-apply.out" >/dev/null || fail "tilde bash-common remediation apply"
grep -F -x '# preceding owner line' "$bash_common_tilde_home/.bashrc" >/dev/null ||
    fail "tilde bash-common remediation damaged preceding content"
grep -F -x 'export AFTER_BLOCK=retained' "$bash_common_tilde_home/.bashrc" >/dev/null ||
    fail "tilde bash-common remediation damaged following content"

bash_common_ambiguous_home=$TEMP_DIR/bash-common-remediation-ambiguous-home
mkdir -p "$bash_common_ambiguous_home"
cat >"$bash_common_ambiguous_home/.bashrc" <<'EOF'
# Source .bash_common
if [ -f "$HOME/.bash_common" ]; then
. "$HOME/.bash_common"
fi
# Source .bash_common
EOF
cp "$bash_common_ambiguous_home/.bashrc" "$TEMP_DIR/original-ambiguous-bashrc"
if HOME="$bash_common_ambiguous_home" "$test_repo/bin/harness" remediate --host t4 \
    --remove-bash-common-reference --apply >"$TEMP_DIR/bash-common-ambiguous.out" 2>&1; then
    fail "bash-common remediation accepted an ambiguous block"
fi
cmp -s "$bash_common_ambiguous_home/.bashrc" "$TEMP_DIR/original-ambiguous-bashrc" ||
    fail "refused bash-common remediation changed the destination"

HOME="$test_home" "$test_repo/bin/harness" shell --host al --plan \
    >"$TEMP_DIR/al-shell-plan.out"
al_payload_bytes=$((1 + $(wc -c <"$test_repo/shell/bashrc.al.block" | tr -d ' ')))
grep "APPEND file=.bashrc bytes=$al_payload_bytes" "$TEMP_DIR/al-shell-plan.out" \
    >/dev/null || fail "al host-specific shell payload"
al_profile_payload_bytes=$((1 + $(wc -c <"$test_repo/shell/bash_profile.al.block" | tr -d ' ')))
grep "APPEND file=.bash_profile bytes=$al_profile_payload_bytes" \
    "$TEMP_DIR/al-shell-plan.out" >/dev/null || fail "al host-specific login payload"
if HOME="$test_home" "$test_repo/bin/harness" remediate --host rc --plan \
    >"$TEMP_DIR/unknown-remediation.out" 2>&1; then
    fail "remediation accepted an unreviewed host"
fi
ln -s "$test_repo" "$test_home/harness"
if HOME="$test_home" bash --noprofile --norc -c \
    '. "$HOME/harness/shell/bashrc.al.block"; type prgenv >/dev/null 2>&1'; then
    fail "al convenience loaded in a non-interactive shell"
fi
env -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$test_home" bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/bashrc.al.block"; type prgenv' \
    >"$TEMP_DIR/al-interactive.out" 2>&1 || fail "al interactive convenience"
grep 'prgenv is a function' "$TEMP_DIR/al-interactive.out" >/dev/null ||
    fail "al interactive function missing"

profile_home=$TEMP_DIR/profile-home
mkdir -p "$profile_home"
printf '%s\n' '# existing interactive setup' >"$profile_home/.bashrc"
printf '%s\n' '# existing login setup' >"$profile_home/.profile"
HOME="$profile_home" "$test_repo/bin/harness" shell --host ri --plan \
    >"$TEMP_DIR/profile-shell-plan.out"
grep 'APPEND file=.profile' "$TEMP_DIR/profile-shell-plan.out" >/dev/null ||
    fail "existing profile login selection"
if grep 'file=.bash_profile' "$TEMP_DIR/profile-shell-plan.out" >/dev/null; then
    fail "shell plan bypassed existing profile"
fi
cp "$profile_home/.bashrc" "$TEMP_DIR/original-profile-bashrc"
cp "$profile_home/.profile" "$TEMP_DIR/original-profile-login"
HOME="$profile_home" "$test_repo/bin/harness" shell --host local --apply \
    >"$TEMP_DIR/profile-shell-apply.out"
profile_shell_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/profile-shell-apply.out")
[ -n "$profile_shell_transaction" ] || fail "missing profile shell transaction"
[ ! -e "$profile_home/.bash_profile" ] || fail "shell apply created bash profile"
grep -F '# >>> harness managed >>>' "$profile_home/.profile" >/dev/null ||
    fail "shell apply missed existing profile"
HOME="$profile_home" "$test_repo/bin/harness" rollback "$profile_shell_transaction" \
    >"$TEMP_DIR/profile-shell-rollback.out"
cmp -s "$profile_home/.bashrc" "$TEMP_DIR/original-profile-bashrc" ||
    fail "profile-selection bashrc rollback"
cmp -s "$profile_home/.profile" "$TEMP_DIR/original-profile-login" ||
    fail "profile-selection login rollback"
[ ! -e "$profile_home/.bash_profile" ] || fail "rollback created bash profile"

new_shell_home=$TEMP_DIR/new-shell-home
mkdir -p "$new_shell_home"
HOME="$new_shell_home" "$test_repo/bin/harness" shell --host local --plan \
    >"$TEMP_DIR/new-shell-plan.out"
grep 'CREATE file=.bashrc' "$TEMP_DIR/new-shell-plan.out" >/dev/null ||
    fail "absent bashrc creation plan"
grep 'CREATE file=.profile' "$TEMP_DIR/new-shell-plan.out" >/dev/null ||
    fail "absent profile creation plan"
HOME="$new_shell_home" "$test_repo/bin/harness" shell --host local --apply \
    >"$TEMP_DIR/new-shell-apply.out"
new_shell_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/new-shell-apply.out")
[ -f "$new_shell_home/.bashrc" ] && [ -f "$new_shell_home/.profile" ] ||
    fail "absent shell files were not created"
HOME="$new_shell_home" "$test_repo/bin/harness" rollback "$new_shell_transaction" \
    >"$TEMP_DIR/new-shell-rollback.out"
[ ! -e "$new_shell_home/.bashrc" ] && [ ! -e "$new_shell_home/.profile" ] ||
    fail "new shell file rollback"

dotfile_home=$TEMP_DIR/dotfile-home
mkdir -p "$dotfile_home/.ssh"
printf '%s\n' 'set number' >"$dotfile_home/.vimrc"
printf '%s\n' 'Host node-only' '    HostName node.invalid' \
    >"$dotfile_home/.ssh/config"
cp "$dotfile_home/.vimrc" "$TEMP_DIR/original-vimrc"
cp "$dotfile_home/.ssh/config" "$TEMP_DIR/original-ssh-config"
HOME="$dotfile_home" "$test_repo/bin/harness" dotfiles --host local --plan \
    >"$TEMP_DIR/dotfile-plan.out"
grep 'REPLACE file=.*\.vimrc reason=owner-approved-canonical-version' \
    "$TEMP_DIR/dotfile-plan.out" >/dev/null || fail "canonical Vim plan"
grep 'APPEND file=.*\.ssh/config contents=single-managed-include' \
    "$TEMP_DIR/dotfile-plan.out" >/dev/null || fail "SSH include plan"
HOME="$dotfile_home" "$test_repo/bin/harness" dotfiles --host local --apply \
    >"$TEMP_DIR/dotfile-apply.out"
dotfile_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/dotfile-apply.out")
[ "$(readlink "$dotfile_home/.vimrc")" = "$test_repo/config/vim/vimrc" ] ||
    fail "canonical Vim link"
[ "$(readlink "$dotfile_home/.ssh/config.d/harness.conf")" = \
    "$test_repo/config/ssh/harness.conf" ] || fail "shared SSH fragment link"
[ "$(grep -c '^Include ~/.ssh/config.d/harness.conf$' \
    "$dotfile_home/.ssh/config")" -eq 1 ] || fail "single SSH include"
HOME="$dotfile_home" "$test_repo/bin/harness" rollback "$dotfile_transaction" \
    >"$TEMP_DIR/dotfile-rollback.out"
cmp -s "$dotfile_home/.vimrc" "$TEMP_DIR/original-vimrc" ||
    fail "Vim rollback"
cmp -s "$dotfile_home/.ssh/config" "$TEMP_DIR/original-ssh-config" ||
    fail "SSH include rollback"
[ ! -e "$dotfile_home/.ssh/config.d/harness.conf" ] ||
    fail "SSH fragment rollback"

# Site startup may put another user or project command directory before the
# managed bin. The portable profile must move its directory to the front and
# remove duplicates without losing the remaining order.
profile_path_home=$TEMP_DIR/profile-path-home
mkdir -p "$profile_path_home/.local/bin"
HOME="$profile_path_home" \
    PATH="/site/project/bin:$profile_path_home/.local/bin:/usr/bin:$profile_path_home/.local/bin:/bin" \
    HARNESS_PROFILE="$test_repo/shell/profile.sh" \
    EXPECTED_PATH="$profile_path_home/.local/bin:/site/project/bin:/usr/bin:/bin" \
    sh -c '. "$HARNESS_PROFILE"; [ "$PATH" = "$EXPECTED_PATH" ]' ||
    fail "managed bin path precedence"

# Exercise exact-member ZIP apply and rollback without network access.
fake_bin=$TEMP_DIR/fake-bin
mkdir -p "$fake_bin"
printf '%s\n' \
    '#!/bin/sh' \
    'out=' \
    'while [ "$#" -gt 0 ]; do' \
    '    case "$1" in' \
    '        -o) out=$2; shift 2 ;;' \
    '        *) shift ;;' \
    '    esac' \
    'done' \
    '[ -n "$out" ]' \
    'cp "$FIXTURE_ARCHIVE" "$out"' >"$fake_bin/curl"
chmod 755 "$fake_bin/curl"
printf '%s\n' \
    '#!/bin/sh' \
    '[ "$1" = --fsys-tarfile ]' \
    'cat "$2"' >"$fake_bin/dpkg-deb"
chmod 755 "$fake_bin/dpkg-deb"
HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" FIXTURE_ARCHIVE="$zip_fixture_archive" \
    "$test_repo/bin/harness" tool --host local --name rclone --apply \
    >"$TEMP_DIR/zip-tool-apply.out"
zip_tool_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/zip-tool-apply.out")
[ -n "$zip_tool_transaction" ] || fail "missing ZIP tool transaction"
grep "NATIVE unzip -p STAGING $zip_fixture_member > STAGING/rclone" \
    "$TEMP_DIR/zip-tool-apply.out" >/dev/null || fail "ZIP native extraction report"
grep "CALLER native='hash -r' reason=refresh-command-path-cache" \
    "$TEMP_DIR/zip-tool-apply.out" >/dev/null || fail "tool caller cache refresh"
HOME="$test_home" PATH="/usr/bin:/bin" \
    "$test_home/.local/bin/rclone" --version >"$TEMP_DIR/zip-tool-version.out"
grep '^rclone v1.74.3$' "$TEMP_DIR/zip-tool-version.out" >/dev/null ||
    fail "ZIP installed version"
HOME="$test_home" PATH="/usr/bin:/bin" \
    "$test_repo/bin/harness" tool --host local --name rclone --plan \
    >"$TEMP_DIR/zip-tool-repeat.out"
grep 'KEEP command=rclone source=managed-artifact' "$TEMP_DIR/zip-tool-repeat.out" \
    >/dev/null || fail "ZIP managed artifact plan"
HOME="$test_home" "$test_repo/bin/harness" rollback "$zip_tool_transaction" \
    >"$TEMP_DIR/zip-tool-rollback.out"
[ ! -e "$test_home/.local/bin/rclone" ] && [ ! -L "$test_home/.local/bin/rclone" ] ||
    fail "ZIP rollback left stable link"
[ ! -e "$test_home/.local/opt/rclone/1.74.3/linux-x86_64" ] ||
    fail "ZIP rollback left artifact directory"

# Exercise the single-binary bzip2 release format used by Restic.
HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" \
    FIXTURE_ARCHIVE="$restic_fixture.bz2" \
    "$test_repo/bin/harness" tool --host local --name restic --apply \
    >"$TEMP_DIR/restic-tool-apply.out"
restic_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/restic-tool-apply.out")
[ -n "$restic_transaction" ] || fail "missing Restic transaction"
grep 'NATIVE bzip2 -dc STAGING > STAGING/restic' \
    "$TEMP_DIR/restic-tool-apply.out" >/dev/null || fail "Restic native extraction report"
[ "$("$test_home/.local/bin/restic" version)" = \
    'restic 0.19.1 compiled with go1.26.0 on linux/amd64' ] ||
    fail "Restic installed version"
HOME="$test_home" "$test_repo/bin/harness" rollback "$restic_transaction" \
    >"$TEMP_DIR/restic-tool-rollback.out"
[ ! -e "$test_home/.local/bin/restic" ] && [ ! -L "$test_home/.local/bin/restic" ] ||
    fail "Restic rollback left stable link"
[ ! -e "$test_home/.local/opt/restic/0.19.1/linux-x86_64" ] ||
    fail "Restic rollback left artifact directory"

# Exercise a root-member tar archive through the same exact-output path.
HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" \
    FIXTURE_ARCHIVE="$tectonic_fixture_archive" \
    "$test_repo/bin/harness" tool --host local --name tectonic --apply \
    >"$TEMP_DIR/tectonic-tool-apply.out"
tectonic_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/tectonic-tool-apply.out")
[ -n "$tectonic_transaction" ] || fail "missing Tectonic transaction"
grep 'NATIVE tar -xOzf STAGING tectonic > STAGING/tectonic' \
    "$TEMP_DIR/tectonic-tool-apply.out" >/dev/null || fail "root-member tar extraction report"
[ "$(HOME="$test_home" "$test_home/.local/bin/tectonic" --version)" = 'Tectonic 0.16.9' ] ||
    fail "Tectonic installed version"
HOME="$test_home" "$test_repo/bin/harness" rollback "$tectonic_transaction" \
    >"$TEMP_DIR/tectonic-tool-rollback.out"
[ ! -e "$test_home/.local/bin/tectonic" ] && [ ! -L "$test_home/.local/bin/tectonic" ] ||
    fail "Tectonic rollback left stable link"
[ ! -e "$test_home/.local/opt/tectonic/0.16.9/linux-x86_64" ] ||
    fail "Tectonic rollback left artifact directory"

# Exercise ShellCheck's multi-line version gate, exact-member apply,
# idempotence, tamper refusal, and rollback.
HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" \
    FIXTURE_ARCHIVE="$shellcheck_fixture_archive" \
    "$test_repo/bin/harness" tool --host local --name shellcheck --apply \
    >"$TEMP_DIR/shellcheck-tool-apply.out"
shellcheck_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/shellcheck-tool-apply.out")
[ -n "$shellcheck_transaction" ] || fail "missing ShellCheck transaction"
grep 'NATIVE tar -xOzf STAGING shellcheck-v0.11.0/shellcheck > STAGING/shellcheck' \
    "$TEMP_DIR/shellcheck-tool-apply.out" >/dev/null ||
    fail "ShellCheck native extraction report"
shellcheck_binary=$test_home/.local/opt/shellcheck/0.11.0/linux-x86_64/shellcheck
"$shellcheck_binary" --version | grep '^version: 0.11.0$' >/dev/null ||
    fail "ShellCheck installed version"
HOME="$test_home" PATH="/usr/bin:/bin" \
    "$test_repo/bin/harness" tool --host local --name shellcheck --plan \
    >"$TEMP_DIR/shellcheck-tool-repeat.out"
grep 'KEEP command=shellcheck source=managed-artifact' \
    "$TEMP_DIR/shellcheck-tool-repeat.out" >/dev/null ||
    fail "ShellCheck managed artifact plan"
cp -p "$shellcheck_binary" "$TEMP_DIR/original-shellcheck-binary"
printf '%s\n' tampered >>"$shellcheck_binary"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$shellcheck_transaction" \
    >"$TEMP_DIR/refused-shellcheck-rollback.out" 2>&1; then
    fail "ShellCheck rollback accepted changed binary"
fi
cp -p "$TEMP_DIR/original-shellcheck-binary" "$shellcheck_binary"
HOME="$test_home" "$test_repo/bin/harness" rollback "$shellcheck_transaction" \
    >"$TEMP_DIR/shellcheck-tool-rollback.out"
[ ! -e "$test_home/.local/bin/shellcheck" ] &&
    [ ! -L "$test_home/.local/bin/shellcheck" ] ||
    fail "ShellCheck rollback left stable link"
[ ! -e "$test_home/.local/opt/shellcheck/0.11.0/linux-x86_64" ] ||
    fail "ShellCheck rollback left artifact directory"

# Exercise the checksum-pinned source build, tamper refusal, and exact cleanup.
source_bin=$TEMP_DIR/source-bin
mkdir -p "$source_bin"
ln -s "$fake_bin/curl" "$source_bin/curl"
for command_name in as awk bash cc chmod cmp cp date dirname find getent git grep gzip id ld ln \
    mkdir mktemp mv readlink realpath rm rmdir sed sh sha256sum stat tail tar tr \
    uname unlink unzip wc; do
    ln -s "$(command -v "$command_name")" "$source_bin/$command_name"
done
HOME="$test_home" PATH="$source_bin" FIXTURE_ARCHIVE="$sqlite_fixture_archive" \
    "$test_repo/bin/harness" build-tool --host local --name sqlite --apply \
    >"$TEMP_DIR/sqlite-build-apply.out"
sqlite_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/sqlite-build-apply.out")
[ -n "$sqlite_transaction" ] || fail "missing SQLite source-build transaction"
grep '^NATIVE cc -O2 ' "$TEMP_DIR/sqlite-build-apply.out" >/dev/null ||
    fail "SQLite native compile report"
sqlite_tree=$test_home/.local/opt/sqlite/3.53.3/linux-x86_64
sqlite_binary=$sqlite_tree/sqlite3
[ "$($sqlite_binary --version)" = '3.53.3 fixture' ] || fail "SQLite built version"
HOME="$test_home" PATH="$source_bin" \
    "$test_repo/bin/harness" build-tool --host local --name sqlite --plan \
    >"$TEMP_DIR/sqlite-build-repeat.out"
grep 'KEEP command=sqlite3 source=managed-source-build' \
    "$TEMP_DIR/sqlite-build-repeat.out" >/dev/null || fail "SQLite managed source-build plan"
cp -p "$sqlite_binary" "$TEMP_DIR/original-sqlite-binary"
printf '%s\n' changed >>"$sqlite_binary"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$sqlite_transaction" \
    >"$TEMP_DIR/refused-sqlite-rollback.out" 2>&1; then
    fail "SQLite rollback accepted changed binary"
fi
[ -L "$test_home/.local/bin/sqlite3" ] && [ -d "$sqlite_tree" ] ||
    fail "SQLite rollback partially mutated paths"
cp -p "$TEMP_DIR/original-sqlite-binary" "$sqlite_binary"
HOME="$test_home" "$test_repo/bin/harness" rollback "$sqlite_transaction" \
    >"$TEMP_DIR/sqlite-build-rollback.out"
[ ! -e "$test_home/.local/bin/sqlite3" ] && [ ! -L "$test_home/.local/bin/sqlite3" ] ||
    fail "SQLite rollback left stable link"
[ ! -e "$sqlite_tree" ] || fail "SQLite rollback left artifact directory"

HOME="$test_home" PATH="$source_bin" FIXTURE_ARCHIVE="$tree_fixture_archive" \
    "$test_repo/bin/harness" build-tool --host local --name tree --apply \
    >"$TEMP_DIR/tree-build-apply.out"
tree_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/tree-build-apply.out")
[ -n "$tree_transaction" ] || fail "missing Tree source-build transaction"
grep '^NATIVE cc -O2 -DLARGEFILE_SOURCE ' "$TEMP_DIR/tree-build-apply.out" \
    >/dev/null || fail "Tree native compile report"
tree_tree=$test_home/.local/opt/tree/2.3.2/linux-x86_64
tree_binary=$tree_tree/tree
[ "$($tree_binary --version)" = 'tree v2.3.2 fixture' ] || fail "Tree built version"
HOME="$test_home" PATH="$source_bin" \
    "$test_repo/bin/harness" build-tool --host local --name tree --plan \
    >"$TEMP_DIR/tree-build-repeat.out"
grep 'KEEP command=tree source=managed-source-build' \
    "$TEMP_DIR/tree-build-repeat.out" >/dev/null || fail "Tree managed source-build plan"
cp -p "$tree_binary" "$TEMP_DIR/original-tree-binary"
printf '%s\n' changed >>"$tree_binary"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$tree_transaction" \
    >"$TEMP_DIR/refused-tree-rollback.out" 2>&1; then
    fail "Tree rollback accepted changed binary"
fi
[ -L "$test_home/.local/bin/tree" ] && [ -d "$tree_tree" ] ||
    fail "Tree rollback partially mutated paths"
cp -p "$TEMP_DIR/original-tree-binary" "$tree_binary"
HOME="$test_home" "$test_repo/bin/harness" rollback "$tree_transaction" \
    >"$TEMP_DIR/tree-build-rollback.out"
[ ! -e "$test_home/.local/bin/tree" ] && [ ! -L "$test_home/.local/bin/tree" ] ||
    fail "Tree rollback left stable link"
[ ! -e "$tree_tree" ] || fail "Tree rollback left artifact directory"

# Exercise whole-tree runtime apply, changed-tree refusal, and exact rollback.
runtime_bin=$TEMP_DIR/runtime-bin
runtime_home=$TEMP_DIR/runtime-home-link
ln -s "$test_home" "$runtime_home"
mkdir -p "$runtime_bin"
ln -s "$fake_bin/curl" "$runtime_bin/curl"
for command_name in awk bash chmod cmp cp date dd dirname find getent git gzip id ln mkdir \
    mktemp mv readlink realpath rm rmdir sed sh sha256sum stat tail tar tr uname unlink wc; do
    ln -s "$(command -v "$command_name")" "$runtime_bin/$command_name"
done
HOME="$runtime_home" PATH="$runtime_bin" FIXTURE_ARCHIVE="$runtime_fixture_archive" \
    "$test_repo/bin/harness" runtime --host local --name node --apply \
    >"$TEMP_DIR/runtime-apply.out"
runtime_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/runtime-apply.out")
[ -n "$runtime_transaction" ] || fail "missing runtime transaction"
HOME="$runtime_home" PATH="$runtime_bin" \
    "$test_repo/bin/harness" runtime --host local --name node --plan \
    >"$TEMP_DIR/runtime-repeat.out"
grep 'KEEP runtime=node source=managed-runtime' "$TEMP_DIR/runtime-repeat.out" \
    >/dev/null || fail "managed runtime plan"
runtime_tree=$runtime_home/.local/opt/node/24.16.0/linux-x86_64
cp -p "$runtime_tree/lib/npm.sh" "$TEMP_DIR/original-runtime-npm"
printf '%s\n' '# changed after apply' >>"$runtime_tree/lib/npm.sh"
if HOME="$runtime_home" "$test_repo/bin/harness" rollback "$runtime_transaction" \
    >"$TEMP_DIR/refused-runtime-rollback.out" 2>&1; then
    fail "runtime rollback accepted changed tree"
fi
[ -L "$runtime_home/.local/bin/node" ] && [ -d "$runtime_tree" ] ||
    fail "runtime rollback partially mutated paths"
cp -p "$TEMP_DIR/original-runtime-npm" "$runtime_tree/lib/npm.sh"
HOME="$runtime_home" "$test_repo/bin/harness" rollback "$runtime_transaction" \
    >"$TEMP_DIR/runtime-rollback.out"
for command_name in node npm npx corepack; do
    [ ! -e "$runtime_home/.local/bin/$command_name" ] &&
        [ ! -L "$runtime_home/.local/bin/$command_name" ] ||
        fail "runtime rollback left link: $command_name"
done
[ ! -e "$runtime_tree" ] || fail "runtime rollback left tree"

# Exercise the two-archive agent tree, changed-tree refusal, and exact rollback.
agent_bin=$TEMP_DIR/agent-bin
agent_home=$TEMP_DIR/agent-home-link
ln -s "$test_home" "$agent_home"
mkdir -p "$agent_bin"
for command_name in awk bash chmod cmp cp date dirname find getent git gzip id ln mkdir \
    mktemp mv readlink realpath rm rmdir sed sh sha256sum stat tar tr uname unlink wc; do
    ln -s "$(command -v "$command_name")" "$agent_bin/$command_name"
done
printf '%s\n' '#!/bin/sh' 'echo v24.16.0' >"$agent_bin/node"
chmod 755 "$agent_bin/node"
printf '%s\n' \
    '#!/bin/sh' \
    'url=' \
    'out=' \
    'while [ "$#" -gt 0 ]; do' \
    '  case "$1" in' \
    '    https://*) url=$1; shift ;;' \
    '    -o) out=$2; shift 2 ;;' \
    '    *) shift ;;' \
    '  esac' \
    'done' \
    'case "$url" in' \
    '  *linux-x64*) cp "$FIXTURE_AGENT_NATIVE" "$out" ;;' \
    '  *) cp "$FIXTURE_AGENT_LAUNCHER" "$out" ;;' \
    'esac' >"$agent_bin/curl"
chmod 755 "$agent_bin/curl"
HOME="$agent_home" PATH="$agent_bin" \
    FIXTURE_AGENT_LAUNCHER="$agent_launcher_archive" \
    FIXTURE_AGENT_NATIVE="$agent_native_archive" \
    "$test_repo/bin/harness" agent --host local --name codex --apply \
    >"$TEMP_DIR/agent-apply.out"
agent_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/agent-apply.out")
[ -n "$agent_transaction" ] || fail "missing agent transaction"
grep "CALLER native='hash -r' reason=refresh-command-path-cache" \
    "$TEMP_DIR/agent-apply.out" >/dev/null || fail "agent caller cache refresh"
HOME="$agent_home" PATH="$agent_bin" \
    "$test_repo/bin/harness" agent --host local --name codex --plan \
    >"$TEMP_DIR/agent-repeat.out"
grep 'KEEP agent=codex source=managed-agent' "$TEMP_DIR/agent-repeat.out" >/dev/null ||
    fail "managed agent plan"
agent_tree=$agent_home/.local/opt/agents/codex/0.144.4/linux-x86_64
agent_launcher=$agent_tree/node_modules/@openai/codex/bin/codex.js
cp -p "$agent_launcher" "$TEMP_DIR/original-agent-launcher"
printf '%s\n' '# changed after apply' >>"$agent_launcher"
if HOME="$agent_home" "$test_repo/bin/harness" rollback "$agent_transaction" \
    >"$TEMP_DIR/refused-agent-rollback.out" 2>&1; then
    fail "agent rollback accepted changed tree"
fi
[ -L "$agent_home/.local/bin/codex" ] && [ -d "$agent_tree" ] ||
    fail "agent rollback partially mutated paths"
cp -p "$TEMP_DIR/original-agent-launcher" "$agent_launcher"
HOME="$agent_home" "$test_repo/bin/harness" rollback "$agent_transaction" \
    >"$TEMP_DIR/agent-rollback.out"
[ ! -e "$agent_home/.local/bin/codex" ] && [ ! -L "$agent_home/.local/bin/codex" ] ||
    fail "agent rollback left command link"
[ ! -e "$agent_tree" ] || fail "agent rollback left tree"

# Exercise uv-managed Python apply, changed-tree refusal, and exact rollback.
python_bin=$TEMP_DIR/python-bin
python_home=$TEMP_DIR/python-home-link
ln -s "$test_home" "$python_home"
mkdir -p "$python_bin"
for command_name in awk bash chmod cmp cp date dd dirname find getent git id ln mkdir mktemp \
    mv readlink realpath rm rmdir sed sh sha256sum stat tail tar tr uname unlink wc; do
    ln -s "$(command -v "$command_name")" "$python_bin/$command_name"
done
fake_python=$TEMP_DIR/python3.12
printf '%s\n' \
    '#!/bin/sh' \
    'case "${2:-}" in' \
    '  *platform.python_version*) echo 3.12.12 ;;' \
    '  *platform.machine*) echo x86_64 ;;' \
    '  *) exit 0 ;;' \
    'esac' \
    'printf "%s\n" "$0" >"${0%/*}/../relocation-state"' >"$fake_python"
chmod 755 "$fake_python"
printf '%s\n' \
    '#!/bin/sh' \
    'if [ "${1:-}" = --version ]; then echo "uv 0.9.18"; exit 0; fi' \
    'install_dir=' \
    'while [ "$#" -gt 0 ]; do' \
    '  case "$1" in --install-dir) install_dir=$2; shift 2 ;; *) shift ;; esac' \
    'done' \
    '[ -n "$install_dir" ]' \
    'target=$install_dir/cpython-3.12.12-linux-x86_64-gnu/bin' \
    'mkdir -p "$target"' \
    'cp "$FIXTURE_PYTHON" "$target/python3.12"' >"$python_bin/uv"
chmod 755 "$python_bin/uv"
HOME="$python_home" PATH="$python_bin" FIXTURE_PYTHON="$fake_python" \
    "$test_repo/bin/harness" python --host local --minor 3.12 --apply \
    >"$TEMP_DIR/python-apply.out"
python_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/python-apply.out")
[ -n "$python_transaction" ] || fail "missing Python transaction"
HOME="$python_home" PATH="$python_bin" \
    "$test_repo/bin/harness" python --host local --minor 3.12 --plan \
    >"$TEMP_DIR/python-repeat.out"
grep 'KEEP python=3.12 source=managed-python' "$TEMP_DIR/python-repeat.out" \
    >/dev/null || fail "managed Python plan"
python_tree=$python_home/.local/opt/python/3.12/linux-x86_64
python_executable=$(find "$python_tree" -type f -name python3.12 -print -quit)
python_tree_archive=$TEMP_DIR/python-tree.tar
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    --exclude='*/__pycache__' --exclude='*.pyc' --exclude='*.pyo' \
    -cf "$python_tree_archive" -C "$python_tree" .
python_tree_hash=$(sha256sum "$python_tree_archive" | awk '{print $1}')
python_expected_hash=$(awk -F'|' '$1 == "python" { print $3 }' \
    "$python_home/.local/state/harness/transactions/$python_transaction.manifest")
[ "$python_tree_hash" = "$python_expected_hash" ] || fail "Python tree changed during activation"
cp -p "$python_executable" "$TEMP_DIR/original-python"
printf '%s\n' '# changed after apply' >>"$python_executable"
if HOME="$python_home" "$test_repo/bin/harness" rollback "$python_transaction" \
    >"$TEMP_DIR/refused-python-rollback.out" 2>&1; then
    fail "Python rollback accepted changed tree"
fi
[ -L "$python_home/.local/bin/python3.12" ] && [ -d "$python_tree" ] ||
    fail "Python rollback partially mutated paths"
cp -p "$TEMP_DIR/original-python" "$python_executable"
python_impl=$(find "$python_tree" -mindepth 1 -maxdepth 1 -type d -name 'cpython-*' -print -quit)
mkdir -p "$python_impl/bin/__pycache__"
printf '%s\n' generated-cache >"$python_impl/bin/__pycache__/module.pyc"
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    --exclude='*/__pycache__' --exclude='*.pyc' --exclude='*.pyo' \
    -cf "$python_tree_archive" -C "$python_tree" .
python_restored_hash=$(sha256sum "$python_tree_archive" | awk '{print $1}')
[ "$python_restored_hash" = "$python_expected_hash" ] || fail "Python tree restoration mismatch"
HOME="$python_home" "$test_repo/bin/harness" rollback "$python_transaction" \
    >"$TEMP_DIR/python-rollback.out"
[ ! -e "$python_home/.local/bin/python3.12" ] &&
    [ ! -L "$python_home/.local/bin/python3.12" ] || fail "Python rollback left link"
[ ! -e "$python_tree" ] || fail "Python rollback left tree"

# Exercise artifact rollback and its all-path modification refusal without network.
artifact_dir=$test_home/.local/opt/fixture/1/linux-x86_64
artifact_link=$test_home/.local/bin/fixture
mkdir -p "$artifact_dir" "${artifact_link%/*}"
printf '%s\n' fixture-binary >"$artifact_dir/fixture"
chmod 755 "$artifact_dir/fixture"
artifact_hash=$(sha256sum "$artifact_dir/fixture" | awk '{print $1}')
ln -s "$artifact_dir/fixture" "$artifact_link"
artifact_transaction='fixture-artifact'
artifact_manifest=$test_home/.local/state/harness/transactions/$artifact_transaction.manifest
printf 'schema=1\nhost=local\nrevision=test\nartifact|%s|fixture|%s\nlink|%s|%s\n' \
    "$artifact_dir" "$artifact_hash" "$artifact_link" "$artifact_dir/fixture" \
    >"$artifact_manifest"
chmod 600 "$artifact_manifest"
printf '%s\n' changed >"$artifact_dir/fixture"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$artifact_transaction" \
    >"$TEMP_DIR/refused-artifact-rollback.out" 2>&1; then
    fail "artifact rollback accepted a changed binary"
fi
[ -L "$artifact_link" ] || fail "artifact rollback partially removed link"
printf '%s\n' fixture-binary >"$artifact_dir/fixture"
chmod 755 "$artifact_dir/fixture"
HOME="$test_home" "$test_repo/bin/harness" rollback "$artifact_transaction" \
    >"$TEMP_DIR/artifact-rollback.out"
[ ! -e "$artifact_link" ] && [ ! -L "$artifact_link" ] ||
    fail "artifact rollback left link"
[ ! -e "$artifact_dir" ] || fail "artifact rollback left directory"

echo "phase-1 harness tests passed"
