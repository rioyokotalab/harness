# Seven-node hidden-home backup and restore gate

This workflow backs up every top-level `~/.*` path, including secret-bearing
paths, without putting their names or contents in Git. Unified non-secret
configuration stays tracked in the harness. Each checkout's ignored
`node-backups/HOST` link points to node-specific retained material outside Git.
Secret-bearing state belongs only in an encrypted Restic repository; its unique
password must also be retained in the owner's external password manager.

The repository map is `profiles/restic-repositories.tsv`. Each node has a
primary repository on its selected persistent storage. Encrypted repository
bytes receive a second, versioned copy at a different site: remote primaries go
to the current node's safe NFS root, while the current node's primary goes to
T4. A versioned empty destination avoids synchronization with deletion and
keeps an independently checkable generation. All seven declared routes are
active; each node must still pass its own manual initialization, full-data
check, restore, and independent-generation gate before scheduling or cleanup.

Restic's documented `backup --files-from-raw`, `check --read-data`, and
`restore --verify` paths are used here. Relevant upstream references are the
[repository setup](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html),
[backup](https://restic.readthedocs.io/en/stable/040_backup.html),
[integrity checking](https://restic.readthedocs.io/en/stable/045_working_with_repos.html#checking-integrity-and-consistency),
and [restore](https://restic.readthedocs.io/en/stable/050_restore.html)
documentation.

## Owner credential step

The owner performs this section personally on each node. Agents must not read,
print, copy, or generate these passwords. Use a different high-entropy password
for every node, save it in an external password manager before initialization,
and create the declared `~/.config/restic/home-control.password` as a regular
mode-0600 file in the node's default home. Do not symlink it to fast or large
storage.

In a fresh interactive login, resolve `HOST` and `PRIMARY` from the matching
profile row without retyping a site path, then run:

```bash
HOST=${HARNESS_LOGICAL_HOST:?missing logical host}
PRIMARY=$(awk -F'|' -v host="$HOST" '$1 == host { print $2 }' \
    "$HOME/harness/profiles/restic-repositories.tsv")
test -n "$PRIMARY"
test -f "$HOME/.config/restic/home-control.password"
test ! -L "$HOME/.config/restic/home-control.password"
test "$(stat -c %a "$HOME/.config/restic/home-control.password")" = 600
PASSWORD_FILE=$HOME/.config/restic/home-control.password
"$HOME/harness/bin/harness" restic -r "$PRIMARY" \
    --password-file "$PASSWORD_FILE" init
```

Initialization is one-time and must fail rather than replace an existing
repository. The password file is intentionally part of the encrypted snapshot,
but that is not a disaster-recovery copy of the password: the external password
manager remains required to open a replica after loss of the node.

## Manual snapshot

Create a private NUL-delimited source manifest. The first command selects every
top-level hidden path without expanding a shell wildcard. The second part adds
the contents behind only the approved relocated symlinks; Restic otherwise
records a symlink but does not traverse it.

```bash
umask 077
SOURCE_MANIFEST=$(mktemp "${TMPDIR:-/tmp}/harness-restic-sources.${HOST}.XXXXXX")
cleanup_source_manifest() {
    if test -f "$SOURCE_MANIFEST" && test ! -L "$SOURCE_MANIFEST"; then
        unlink "$SOURCE_MANIFEST"
    fi
}
trap cleanup_source_manifest EXIT HUP INT TERM

find "$HOME" -mindepth 1 -maxdepth 1 -name '.*' -print0 >"$SOURCE_MANIFEST"
MOVE_LARGE=$(awk -F'|' -v host="$HOST" '$1 == host { print $4 }' \
    "$HOME/harness/profiles/home-layout.tsv")
MOVE_FAST=$(awk -F'|' -v host="$HOST" '$1 == host { print $5 }' \
    "$HOME/harness/profiles/home-layout.tsv")
PERSISTENT_CANONICAL=$(readlink -f "$HARNESS_PERSISTENT_ROOT")
CACHE_CANONICAL=$(readlink -f "$HARNESS_CACHE_ROOT")
for NAME in $(printf '%s,%s\n' "$MOVE_LARGE" "$MOVE_FAST" | tr ',' ' '); do
    test "$NAME" = none && continue
    case "$NAME" in .[A-Za-z0-9._-]*) ;; *) exit 2 ;; esac
    LINK=$HOME/$NAME
    test -L "$LINK" || continue
    TARGET=$(readlink -f "$LINK")
    case "$TARGET" in
        "$PERSISTENT_CANONICAL"/*|"$CACHE_CANONICAL"/*) ;;
        *) printf 'refusing relocated target outside approved roots: %s\n' "$NAME" >&2; exit 2 ;;
    esac
    printf '%s\0' "$TARGET" >>"$SOURCE_MANIFEST"
done
unset NAME LINK TARGET MOVE_LARGE MOVE_FAST PERSISTENT_CANONICAL CACHE_CANONICAL

"$HOME/harness/bin/harness" restic -r "$PRIMARY" \
    --password-file "$PASSWORD_FILE" backup \
    --files-from-raw "$SOURCE_MANIFEST" --host "$HOST" \
    --tag harness-hidden-home-manual
"$HOME/harness/bin/harness" restic -r "$PRIMARY" \
    --password-file "$PASSWORD_FILE" check --read-data
cleanup_source_manifest
trap - EXIT HUP INT TERM
```

Do not add `--exclude-caches`: the requested scope is every hidden path, and
approved high-growth state has already been relocated to quota-appropriate
storage. A backup exit status of 3 is incomplete and does not open the deletion
gate.

## Restore test

Before any approved clean-slate deletion, restore the latest snapshot into a
new empty directory on persistent storage and ask Restic to verify restored
content. This intentionally tests the whole hidden-home snapshot; do not print,
diff, or inspect secret-bearing restored files.

```bash
umask 077
RESTORE_ROOT=$(mktemp -d "$HARNESS_PERSISTENT_ROOT/restic-restore-test.${HOST}.XXXXXX")
"$HOME/harness/bin/harness" restic -r "$PRIMARY" \
    --password-file "$PASSWORD_FILE" restore latest \
    --host "$HOST" --tag harness-hidden-home-manual \
    --target "$RESTORE_ROOT" --verify
"$HOME/harness/bin/harness" restic -r "$PRIMARY" \
    --password-file "$PASSWORD_FILE" snapshots \
    --host "$HOST" --tag harness-hidden-home-manual --compact
```

Record only success status, snapshot ID, time, and aggregate file/byte counts.
Never copy restored secrets into the tracked harness. Remove `RESTORE_ROOT`
only with `harness guarded-delete plan/apply` using its exact canonical path and
immutable token. Only a node with successful `check --read-data` and restore
evidence may enter the recurring workflow below. A newly initialized node joins
the same gate only after its own manual test cycle.

## Scheduler-native weekly primary snapshots

The reviewed schedule is declared in `profiles/restic-schedules.tsv`. It uses
the site's compute scheduler, never login-node cron, a user timer, central SSH,
or a sleeping process. Inspecting the plan and next eligibility is read-only:

```bash
harness restic-schedule plan --host "$HOST"
harness restic-schedule next --host "$HOST"
harness restic-schedule status --host "$HOST"
```

The controller maintains exactly one future job. When admitted, that job first
validates its captured identity and atomically submits or adopts the one
deterministically named successor. Only after the successor is validated and
recorded does it invoke `harness restic-primary weekly`, which creates one
incremental snapshot tagged `harness-hidden-home-weekly`. It does not run
`check --read-data`, restore, replica creation, `forget`, `prune`, or any other
deletion. A delayed queued job remains healthy; if it passes one or more Sunday
points, it runs once and schedules the earliest configured Sunday strictly in
the future rather than backfilling.

Private mode-0600 state lives below
`~/.local/state/harness/restic-chain/`. The interactive shell reads only that
captured state and exact scheduler ID. Healthy and unseeded state is silent;
non-interactive sessions never invoke the warning. A failed snapshot keeps its
already-recorded successor and warns at the next interactive login.

Live activation has two separate gates. First, `smoke` submits a bounded real
allocation that checks architecture/path access, password-file metadata,
managed Restic read-only repository access, and compute-side successor
submission without taking a snapshot. Its captured distant test successor must
be cancelled and verified absent with the exact smoke scope:

```bash
harness restic-schedule smoke --host "$HOST"
harness restic-schedule status --host "$HOST"
harness restic-schedule disable --smoke --host "$HOST"
```

Only after the smoke passes and its successor is absent may `seed` create the
one real future weekly job:

```bash
harness restic-schedule seed --host "$HOST"
harness restic-schedule status --host "$HOST"
```

Disable recurrence only through `harness restic-schedule disable --host
"$HOST"`. It revalidates, prints, cancels, and verifies absence of the one
captured future ID. It never performs a broad user/job-name cancellation or
deletes the retained private evidence. Print and review every reported
`NATIVE` scheduler command during smoke, seed, and disable operations.

## Independent encrypted generation

Generate and review the credential-free route before any live copy:

```bash
harness replica plan --host "$HOST" --generation "$(date -u +%Y%m%dT%H%M%SZ)"
```

The planner is deliberately read-only: it validates the declared direction,
paths, timestamp, staging/final names, and native `rsync -aH`
shape without connecting or copying. Apply is fail-closed on path collisions,
repository symlinks or locks, source drift during the copy, and any mismatch
among source-before, source-after, staging, and promoted fingerprints. A failed
copy retains its new staging directory for diagnosis and guarded cleanup; it
never deletes or overwrites an older generation.

Run this only while no Restic command is writing the primary. From the current
node, copy each remote repository to a newly created generation beneath its
declared local replica root using the existing SSH alias and `rsync -aH`; never
use `--delete`. For the current node, reverse the direction and create the new
generation below the declared T4 root. Verify source/destination entry counts,
bytes, and a sorted SHA-256 manifest of regular files before renaming the
generation from `.staging-TIMESTAMP` to `TIMESTAMP`.

Because this copies only already encrypted repository objects, it needs no
Restic password and must not copy the password file. Validate the finished
generation with the password still resident on its source node, using the
private relay constraints below. Retire old generations only through a
separately planned guarded-delete transaction after a newer generation passes
both integrity and restore tests.

## Replica validation without credential movement

The validated topology keeps the password file on the node that owns it and
serves the encrypted generation from the replica site:

```text
source-node Restic -> mode-0600 reverse Unix socket -> replica-site
                    rclone serve restic --stdio --append-only
```

Use one accepted Unix-socket connection and one `rclone --stdio` child per
Restic command. A persistent `rclone` child can leave shutdown ownership
ambiguous after an otherwise successful transfer. Before opening the relay,
both endpoints must verify an exact allowlisted socket path, socket type,
current user ownership, and mode 0600. The replica-side socket must be changed
to 0600 before SSH creates the reverse forward. Run the server with
`--append-only --cache-objects=false`, and run Restic with `--no-lock
--no-cache`. Do not use TCP listeners, unauthenticated writable service modes,
or SSH authentication exceptions.

On the source node, pass the existing mode-0600 password file to Restic only by
path; never read, print, hash, copy, or forward its bytes. Select the declared
host and `harness-hidden-home-manual` tag, require a nonempty snapshot result,
then run `check --read-data` and `restore latest --verify` into node-local
mode-0700 scratch. Keep command output in an unread mode-0600 temporary log and
record only snapshot count plus aggregate restored entry/byte counts.

Remove the restored tree only through a fresh canonical guarded-delete
plan/apply pair. Exact-unlink the private log, metadata JSON, relay helpers,
manifest, and sockets only after success, and non-recursively remove the empty
restore parent. A final audit must find no Restic/rclone process or validation
temporary path. Every newly initialized route must complete the same manual
validation cycle.
