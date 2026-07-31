# Account and repository boundary

1. Confirm that the task covers one current-user account on Linux or macOS.
   Treat every remote host and private companion repository as out of scope.
2. If already inside a checkout, read its repository instructions. Otherwise
   ask for the repository locator and desired absolute clone path; do not guess
   a private URL or request a credential.
3. Record that every existing dotfile and symlink must be preserved. Package
   installation, administrator commands, client authentication, and collision
   adoption remain separate approval boundaries.

The selected repository and account are the complete mutation boundary.
Checkpoint them and route to preflight; do not discover neighboring accounts,
repositories, SSH configuration, storage, or services.
