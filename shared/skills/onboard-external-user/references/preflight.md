# Prerequisites, clone, and preflight

Before cloning, use native read-only command discovery to require a POSIX shell
and Git. `mkdir`, `ln`, and `readlink` are also required by the installer.
Codex and Claude are optional; report each as present or absent without
installing or authenticating it.

If a required command is missing, identify the operating system and native
package manager, propose the smallest official installation command, and pause
for approval. Never pipe a remote installer into a shell. On macOS, Command
Line Tools installation is an interactive owner step. On Linux, do not infer
sudo or package-manager authority.

Clone with ordinary Git into an absent destination, or reuse only the strict,
clean checkout selected by the user. Do not copy a working tree, SSH
configuration, client state, or credentials. Record the full commit and read
the checkout's `AGENTS.md`, `README.md`, and license or distribution terms.

Run:

```bash
shared/skills/onboard-external-user/scripts/preflight --repo "$ABSOLUTE_CHECKOUT"
```

The preflight may emit only OS/architecture classes, command presence,
checkout cleanliness, and aggregate link states; it never reads destination
contents. Stop on `status=blocked`, a dirty checkout, or any collision.
Explain only the colliding category and let the user choose whether to retain,
move, or separately review adoption. Never overwrite it.
