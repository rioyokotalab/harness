# Personal macOS harness

The personal-Mac target family is independent of the Linux/HPC fleet. It uses
the public harness as an engine and a separate owner-controlled private Git
companion for curated desired intent. No Mac identity, observed inventory,
configuration payload, transaction detail, or credential belongs in the
public repository.

## Private profile validation

The v1 companion contract is defined in
`docs/schemas/personal-macos-private-v1.md`. From a Mac-local session, validate
one opaque profile without printing its values:

```bash
harness macos-profile --host LOGICAL_ID
```

The private checkout must be clean, owner-controlled, mode-restricted, and
contain only `companion.conf` plus strict `hosts/*.conf` manifests. The
resolver validates every tracked host manifest, not only the selected one, and
refuses untracked or modified content.

## Value-minimized observation

`harness macos-inventory --host LOGICAL_ID` is Darwin-only and read-only. It
reports only the OS family, architecture class, native account-shell class,
Homebrew availability and prefix class, Command Line Tools availability,
strict private-profile status, public-checkout status, fixed discovery-link
kinds, and presence of the eight public baseline formulae. It does not print
Homebrew or OS versions, actual prefixes, developer-tool paths, private group
or formula selections, other installed packages, hardware identifiers,
networks, user names, or file contents.

Inventory invokes only `brew --version`, `brew --prefix`, and one scoped
`brew list --formula --versions FORMULA` query for each public formula. It
performs no update, install, upgrade, cleanup, service, tap, bundle, network,
or mutation operation. Private profile failures collapse to `invalid`; their
paths, values, and detailed errors remain suppressed. A live capture must be
written under `umask 077` to the private local harness state, never committed.

## Read-only plan and doctor

`harness macos-plan --host LOGICAL_ID [--facts FILE]` validates a mode-0600
fact snapshot, revalidates the strict private companion, refuses captured/live
formula or link drift, and renders collision-aware link actions. Its only live
Homebrew reads are scoped `brew list --formula --versions FORMULA` and
`brew outdated --formula --quiet FORMULA...` commands with automatic metadata
updates and analytics disabled. It never executes a rendered command.

The plan shows a separately authorized explicit metadata refresh, followed by
exact dry-run and apply commands for only missing or outdated managed formulae.
Install and upgrade commands disable automatic update and cleanup and use
Homebrew's formula-only and dry-run flags while explicitly unsetting
`HOMEBREW_ASK` for no-prompt execution. They do not set
`HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK`: Homebrew documents that disabling
that check can leave broken linkage. The later apply gate must instead inspect
dry-run scope and stop if an unmanaged dependent would change.

`harness macos-doctor --host LOGICAL_ID [--facts FILE]` emits a value-free
ready/not-ready result. It requires a supported architecture, usable Homebrew,
Command Line Tools, a valid private profile, the public checkout, exact managed
link targets, all eight public formulae, and all selected private formulae.
Private formula and capability names are reported only as counts.

Command behavior was frozen against the official Homebrew manpage and FAQ on
2026-07-18:

- <https://docs.brew.sh/Manpage>
- <https://docs.brew.sh/FAQ>
- <https://docs.brew.sh/Versions>

## Transactional discovery links

`harness macos-control --host LOGICAL_ID --plan` validates a canonical clean
public `main` checkout and the strict private profile, then reports only fixed
home-relative discovery-link actions. It manages the harness launcher, Codex
and Claude guidance, Codex rules, and each public shared skill's Codex, Agents,
and Claude discovery links. It does not replace regular files, directories,
different symlinks, symlinked parents, or paths owned by another account.

`harness macos-control --host LOGICAL_ID --apply` repeats every preflight,
creates only missing owner-private parent directories and absent links, and
records exactly what it created in a mode-0600 local transaction. Existing
correct links and existing personal directory modes are preserved. A partial
failure removes only links and directories created by that attempt; a second
successful apply is a no-op.

```bash
harness macos-control --rollback TRANSACTION_ID
```

Rollback first validates the entire private manifest, every recorded link,
every created directory, and the absence of non-transaction content. It then
unlinks only unchanged transaction-owned links and removes only now-empty
transaction-owned directories in reverse order. A changed link, directory,
owner, status, manifest, or unexpected file blocks rollback before mutation.
The transaction record remains local under `~/.local/state/harness`; neither
plan, apply, nor rollback touches packages, shell startup, Git remotes, or the
private repository's contents.

## Bounded Homebrew catch-up

Private `capability_groups` are classification labels and are never converted
into guessed package names. The exact Homebrew allowlist is the eight-formula
public baseline plus the selected private `extra_formulae`. Phase 1 refuses
tapped formula names and tapped dependencies; support for a private tap would
need its own trust, update, and rollback design.

```bash
harness macos-homebrew --host LOGICAL_ID --plan
harness macos-homebrew --host LOGICAL_ID --apply
```

Both modes require Darwin, a canonical clean committed public `main`, a valid
private profile, and one active regular `brew` executable matching its reported
prefix. The command queries versions only for selected formulae, resolves only
their dependency closure, and checks installed dependents of every explicitly
selected root. An installed dependent outside the selected roots is displayed
locally and blocks plan acceptance and apply. Packages that merely share a
dependency remain unmanaged; Homebrew's installed-dependent linkage checks
stay enabled to protect them. It never lists or dumps the whole installed
package set.

Plan runs exact formula-only install and upgrade dry-runs with automatic update,
cleanup, analytics, prompts, and environment hints disabled. It refuses empty
or incomplete dry-run evidence and output that indicates a cask, service,
`sudo`, license, tap, cleanup, uninstall, or autoremove scope. Metadata refresh
remains the separately displayed `brew update` authority; this command does not
run it implicitly.

Apply repeats the checkout, private profile, prefix, selected action set,
dependency closure, installed-dependent, and dry-run gates immediately before
mutation. It then installs only missing selected formulae and upgrades only
outdated selected formulae. Homebrew may update their dependency closure, but
the command does not disable installed-dependent linkage checks because the
official guidance warns that doing so can leave broken linkage. It uses no
cleanup, removal, cask, service, tap, bundle, or whole-machine upgrade command.

Every non-no-op apply records mode-0600 local intent, pre-state, post-state,
dependency delta, command output, and complete/failed status. Homebrew package
changes are not transactionally reversible: failure evidence is retained, and
any downgrade, reinstall, uninstall, or dependency removal remains a separate
exact reviewed recovery action. A converged second apply is a no-op and creates
no transaction.

## Managed Homebrew Bash

`~/.local/bin/harness-bash` is a stable, network-free launcher. It resolves the
active regular `brew`, verifies that the command matches its reported prefix,
checks that the selected `bash` formula is installed, and resolves the Bash
executable inside Homebrew's physical Bash cellar. With no arguments it enters
an interactive login Bash; otherwise it passes the supplied arguments through
unchanged. Its only Homebrew operations are local prefix and named-formula
reads. It never updates metadata, installs or upgrades a package, edits startup
files, or changes the account login shell.

```bash
harness macos-bash --host LOGICAL_ID --plan
harness macos-bash --host LOGICAL_ID --apply
harness macos-bash --rollback TRANSACTION_ID
```

The integration command manages the launcher link, a link to the public thin
interactive loader, and one identical marker-guarded block at the end of both
`.bash_profile` and `.bashrc`. Loading both files directly avoids assuming or
rewriting the owner's existing login/non-login source precedence; an
idempotence guard prevents duplicate loading if an owner profile already
sources `.bashrc`. The loader is silent and inactive in non-interactive Bash.
In an interactive Bash it only marks the managed environment and moves
`~/.local/bin` to the front of `PATH`; it performs no Git, network, Homebrew,
doctor, or background action.

Plan refuses symlinks, non-regular files, foreign owners, hard links, partial
or duplicate markers, link collisions, and unsafe parent/state paths. Apply
hashes the exact expected append before mutation, appends in place, and never
chmods or replaces an existing startup inode, preserving its preceding bytes,
mode, and ACL. New startup files are mode 0600. Rollback validates both complete
post-images and every created link/directory before mutation, then exact-unlinks
created files or truncates existing files to their prior byte count and verifies
their prior hash and mode. Changed owner content blocks rollback. The native
zsh/account-shell recovery route, Terminal preferences, `/etc/shells`, `chsh`,
zsh startup files, Keychain, and login items remain untouched.

## Explicit long-gap update

Fetching is a separate, explicit step. After fetching `origin/main` in both
clean checkouts, resolve each target to its full commit ID locally and review a
read-only plan:

```bash
harness macos-update --host LOGICAL_ID \
  --public-target PUBLIC_COMMIT --private-target PRIVATE_COMMIT --plan
```

The updater requires the expected `main` branch, exactly one `origin`, normal
`origin/main` tracking, a clean worktree, an explicit full target equal to the
fetched `origin/main`, and ancestry from the current revision. It validates the
public engine contract and every file in the private target tree before any
fast-forward. It never rebases, resets, force-updates, autostashes, cleans,
removes packages, or infers desired state from installed tools.

Apply repeats every gate, fast-forwards the public checkout first, hands off to
the target engine, then fast-forwards the private checkout and writes only a
mode-0600 local schema-v1 state record:

```bash
harness macos-update --host LOGICAL_ID \
  --public-target PUBLIC_COMMIT --private-target PRIVATE_COMMIT --apply
```

If the second fast-forward fails after the public update, local machine state
is unchanged and rerunning the same targets is safe. No package, shell, link,
or background action is part of this command. A second successful apply is a
no-op.

Each state change creates a private transaction ID. This command restores only
the prior local state record; it deliberately leaves both Git checkouts at
their current fast-forwarded revisions:

```bash
harness macos-update --rollback TRANSACTION_ID
```

Rollback refuses a changed state record or backup. Reapplying the same target
after rollback is supported. Future schema releases must retain synthetic
fixtures and direct migrations from every previously released schema beginning
with v1; missed deployment events are never replayed.
