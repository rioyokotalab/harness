# Early cache bootstrap

Managed cache variables must exist before an owner or site startup command can
launch a cache-using application. The ordinary harness profile loader remains
an exact suffix so it cannot provide that ordering guarantee by itself.

`harness cache-bootstrap --host HOST --plan` checks, without printing startup
contents, that `.bashrc` and Bash's already-selected login file are strict
owner regular files, retain the exact managed suffix, and have no displaced
early marker. Apply mode prepends a small host-labelled block which sources
`shell/early-cache.sh`. That helper and `shell/cache.sh` are silent and only set
environment variables; they create no directory and perform no network,
scheduler, package, Git, prompt, or application action.

The transaction stores only the public managed prefix. It never stores the
pre-existing startup file or its hash. Prefix insertion uses `ex` with swap,
backup, viminfo, and user configuration disabled. Apply revalidates file type,
owner, managed suffix, marker state, byte count, prefix, and mode. A partial
failure removes only an unchanged exact prefix. Normal rollback validates every
record before changing any file, refuses a changed prefix, and can remove an
unchanged prefix while preserving later owner edits.

The fake-home acceptance gate proves:

- exact-prefix placement and idempotent plans for both startup files;
- cache visibility to the first owner command in each file;
- silent execution without creating `~/.cache`;
- no copying of a synthetic pre-existing secret into transaction state;
- refusal of a changed-prefix rollback before any file is mutated; and
- successful rollback that preserves later owner changes and the managed
  suffix.

Live rollout requires a clean checkout at the tested revision, a clean plan on
each node, transaction-ID capture, fresh login/non-interactive/nested-shell
checks, exact cache-variable comparison with the declared root, and a
postflight confirming that startup itself did not recreate default-home cache
state. Any recurring tree is cleaned only through guarded deletion after the
ordering fix is proven.

## Live outcome

All seven nodes applied the prefix transaction and retained their original
startup-file modes. Fresh direct SSH, login, inherited non-interactive,
interactive, and nested Bash checks see the declared cache values. The native
batch gate explicitly removes inherited values before entering login Bash; all
seven scheduler records and terminal results report zero. Machine-readable
evidence is in
[`audits/cache-startup-readiness-2026-07-16.json`](audits/cache-startup-readiness-2026-07-16.json).

AB and AB2 remained free of their pre-fix default cache directories after
guarded cleanup. RI recreated a tiny directory even through an SFTP subsystem
session, which does not execute Bash startup files. That distinct site/PAM or
concurrent-process behavior is outside this bootstrap's causal scope and is
tracked separately; repeated deletion and broad `HOME` redirection are not
acceptable substitutes for attribution.
