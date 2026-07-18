# Personal macOS private companion schema v1

The public harness resolves desired state from the fixed local checkout
`~/.config/harness/private`. This path is intentionally outside the public
repository. The checkout root, `.git`, and `hosts` directories must be owned by
the current user, mode 0700, and not symlinks. `companion.conf` and the selected
`hosts/LOGICAL_ID.conf` must be owned by the current user, mode 0600, and not
symlinks. Clone or create the future private repository under `umask 077`.

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
names. Installed state is never used to populate either field.

Only curated desired intent belongs in the companion. Hostnames, user names,
serial or hardware identifiers, network details, local paths, copied
configuration, observed inventories, facts, transaction records, histories,
credentials, tokens, keys, and secret values are prohibited, including in
comments. Runtime facts and rollback evidence stay under the Mac's private
local harness state and are reconstructed when not recoverable from the
owner's existing backup.

The tracked example under
`profiles/personal-macos/private-companion.example/` is synthetic and
value-free. It is documentation and a test input, not a private checkout and
does not satisfy the required private modes until copied into an owner-created
private repository.
