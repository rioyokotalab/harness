# Personal macOS private companion schema v1

The public harness resolves desired state from the fixed local checkout
`~/.config/harness/private`. This path is intentionally outside the public
repository. The checkout root, `.git`, and `hosts` directories must be owned by
the current user, mode 0700, and not symlinks. `companion.conf`, the selected
`hosts/LOGICAL_ID.conf`, and an adopted `ssh_config` payload must be owned by
the current user, mode 0600, regular, single-linked files and not symlinks.
Clone or create the future private repository under `umask 077`.

Files are strict, non-executed `key=value` manifests. Blank lines are allowed;
comments, whitespace padding, duplicate or unknown keys, additional `=`, and
control characters are rejected. The resolver never sources either file and
never prints their paths or private values.

`companion.conf` contains exactly:

```text
schema=1
minimum_engine_schema=1
```

The selected host file contains exactly these keys:

```text
schema=1
logical_id=mac-test-example
baseline=macos-cli-v1
capability_groups=none
extra_formulae=none
```

`logical_id` is an opaque identifier using only letters, digits, `.`, `_`, and
`-`; it must match the filename. `baseline` selects the public
`macos-cli-v1` formula set. `capability_groups` is `none` or a duplicate-free
comma-separated list of safe group identifiers. `extra_formulae` is `none` or
a duplicate-free comma-separated list of syntactically safe Homebrew formula
names. Capability-group labels classify private intent; the Homebrew adapter
does not infer package names from them. Every privately selected Homebrew
formula must therefore be named explicitly in `extra_formulae`. Phase 1
catch-up further refuses tapped formula names even though the general token
grammar reserves `/` for a future separately designed tap contract. Installed
state is never used to populate either field.

Only curated desired intent belongs in the manifests. Hostnames, user names,
serial or hardware identifiers, network details, local paths, copied
configuration, observed inventories, facts, transaction records, histories,
credentials, tokens, keys, and secret values remain prohibited in those
manifests, including in comments. Runtime facts and rollback evidence stay under the Mac's private
local harness state and are reconstructed when not recoverable from the
owner's existing backup.

The one deliberate exception is an optional repository-root file named
`ssh_config`. Its presence means whole-file SSH synchronization has been
adopted; its absence is the compatible pre-adoption v1 layout. No other copied
configuration path is allowed. The payload may contain the private host,
account, network, and path values required by OpenSSH, but it must contain only
SSH configuration—not private-key bytes, passwords, tokens, agent state,
`known_hosts`, runtime facts, or transaction data. `Include` and `Match exec`
are rejected so validation cannot read or execute another private file or
command. It is limited to 1 MiB and must pass a canonicalization-disabled
`ssh -G` validation before publication or apply. Git must represent it as one
ordinary non-executable blob. Public logs,
tests, commits, task ledgers, and CI artifacts never contain its bytes, path
values, content hash, or revision; public tests use only the synthetic fixture.

First adoption is explicit. `harness macos-ssh-sync --host LOGICAL_ID --seed`
reviews the existing local config as the initial candidate. Once present,
there is exactly one shared payload and every Mac is an equal writer under the
fail-closed fast-forward protocol. Keys, `known_hosts`, and every other
`~/.ssh` entry remain outside the companion.

The tracked example under
`profiles/personal-macos/private-companion.example/` is synthetic and
value-free. It is documentation and a test input, not a private checkout and
does not satisfy the required private modes until copied into an owner-created
private repository.
