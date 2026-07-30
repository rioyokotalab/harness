# Bootstrap and migration

Transfer a verified credential-free Git bundle of the exact clean commit.
Never copy a working tree, SSH configuration, Git credential, Restic password,
or agent state. Verify bundle mode and commit identity, then create a checkout
or fast-forward an existing clean checkout. Stop on dirt, divergence, wrong
identity, or unexpected symlinks. Exact-unlink the short-lived bundle after
verified use.

Run every mutating Harness command in `plan` mode first and save its value-free
ledger plan. Revalidate remote identity and roots immediately before `apply`;
use existing transactional Harness operations for
control-plane links, shell blocks, dotfiles, and portable tools.

Follow the approved `profiles/home-layout.tsv` row. Retain a verified copy
until links, applications, and backup restores pass.
