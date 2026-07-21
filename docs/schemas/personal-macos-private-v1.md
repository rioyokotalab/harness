# Personal macOS private companion schema v1

The public harness resolves desired state from the fixed local checkout
`~/.config/harness/private`. This path is intentionally outside the public
repository. The checkout root, `.git`, and `hosts` directories must be owned by
the current user, mode 0700, and not symlinks. `companion.conf`, the selected
`hosts/LOGICAL_ID.conf`, and every adopted configuration payload must be owned
by the current user, mode 0600, regular, single-linked files and not symlinks.
Clone or create the future private repository under `umask 077`.

Files are strict, non-executed `key=value` manifests. Blank lines are allowed;
comments, whitespace padding, duplicate or unknown keys, additional `=`, and
control characters are rejected. The resolver never sources either file and
never prints their paths or private values.

`companion.conf` contains exactly one of these compatible engine requirements:

```text
schema=1
minimum_engine_schema=1
```

or, only while an older Mac is awaiting migration from the historical atomic
configuration bundle:

```text
schema=1
minimum_engine_schema=2
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
state is never used to populate either field. A private formula may not overlap
either the current public managed set or the public retirement set.

Only curated desired intent belongs in the manifests. Hostnames, user names,
serial or hardware identifiers, network details, local paths, copied
configuration, observed inventories, facts, transaction records, histories,
credentials, tokens, keys, and secret values remain prohibited in those
manifests, including in comments. Runtime facts and rollback evidence stay under the Mac's private
local harness state and are reconstructed when not recoverable from the
owner's existing backup.

Engine 1 permits one deliberate optional repository-root file named
`ssh_config`. This is the current layout and cannot contain Bash or tmux
payloads. Engine 2 permits either no payloads or exactly the historical atomic
set `ssh_config`, `bashrc`, and `tmux.conf`; partial sets are invalid. Engine 2
is retained only so a sleeping Mac can public-first fast-forward into the
migration bridge. Git must represent every payload as one ordinary
non-executable blob.

The SSH payload may contain the private host,
account, network, and path values required by OpenSSH, but it must contain only
SSH configuration—not private-key bytes, passwords, tokens, agent state,
`known_hosts`, runtime facts, or transaction data. One exact terminal
`Include ~/.ssh/config.d/harness.conf` is allowed; every other `Include` and
every `Match exec` are rejected. Validation removes the permitted line through
stdin before parsing, so it cannot read or execute another private file or
command. The payload is limited to 1 MiB and must pass a canonicalization-disabled
`ssh -G` validation before publication or apply. Public logs, tests, commits,
task ledgers, and CI artifacts never contain its bytes, path values, content
hash, or revision; public tests use only the synthetic fixture.

In the historical engine-2 layout, the `bashrc` payload is the private shared Bash fragment, not a replacement for
the live `.bashrc`. It is limited to 1 MiB, rejects credential-like assignments
and private-key material, and passes `bash --noprofile --norc -n` without
executing commands. Apply copies it to the owner-only runtime fragment
`~/.config/harness/managed/personal-macos-private.bash`; the existing public
thin loader sources it only in a newly started managed interactive Bash.

In the historical engine-2 layout, the `tmux.conf` payload is the complete desired `~/.tmux.conf`, not a loader or
second runtime fragment. It has the same size and credential-material gates.
Validation uses an isolated tmux server and `source-file -n`, which parses the
complete file but executes none of its commands. Apply replaces only the live
`~/.tmux.conf`; a running tmux server is never reloaded automatically.

SSH-only adoption uses `harness macos-ssh-sync`. An older engine-2 companion
migrates through `harness macos-config-migrate`, which deletes only the tracked
`bashrc` and `tmux.conf` blobs, changes `minimum_engine_schema` to 1, and
normally pushes the private commit forward. Bash then uses the public Linux
pre/local/post layout and tmux uses the public canonical symlink. Private Git
is never force-rewound by local rollback. Keys, `known_hosts`, and every other
`~/.ssh` entry remain outside the companion.

The tracked example under
`profiles/personal-macos/private-companion.example/` is synthetic and
value-free. It is documentation and a test input, not a private checkout and
does not satisfy the required private modes until copied into an owner-created
private repository.
