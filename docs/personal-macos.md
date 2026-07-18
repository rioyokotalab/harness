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
