# User-local terminal compatibility

The shared tmux configuration advertises `tmux-256color`. A managed host must
therefore provide that terminfo entry before terminal applications run inside
tmux. Site-wide terminfo and terminal defaults remain outside this workflow.

AL uses a user-local canonical entry because its system database does not
provide `tmux-256color`:

```bash
harness terminfo --host al --plan
harness terminfo --host al --apply
harness terminfo --host al --rollback TRANSACTION_ID
```

The tracked source is `config/terminfo/tmux-256color.src`. Plan checks that
AL's installed ncurses compiler accepts it and refuses an existing entry whose
normalized capabilities differ. Apply requires a clean harness checkout,
compiles in an identity-checked private transaction staging directory, installs
one regular user-local entry, and validates discovery plus the color
capability. Temporary directory cleanup uses guarded deletion.

Rollback is available only for an entry created by the recorded transaction.
It verifies the installed binary hash and refuses if the entry or any
transaction-created directory gained unrelated content. The command never
changes the system terminfo database, `TERM`, tmux configuration, Vim
configuration, or tty modes.

Acceptance on AL additionally uses a controlled real PTY to check `infocmp`,
`tput`, clean Vim, tracked-config Vim, tty preservation, and alternate-screen
entry/restoration. Those runtime checks distinguish a valid database entry
from merely successful compilation.
