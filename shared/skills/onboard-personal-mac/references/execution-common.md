# Common post-go execution gates

Execute the frozen one-host plan only after explicit `go`. Codex runs commands;
never tell the owner to execute a script. Print the resolved native command
before every remote, Git, package, or Harness action.

- Revalidate before each apply; stop on refusal, ambiguity, or drift.
- Fetch and integrate public and private Git without force-push or ambiguous
  overwrite. Keep private values, revisions, and transaction identifiers out
  of public evidence.
- Plan before apply. Accept only the exact reviewed no-block plan, preserve its
  live preimage, and use transactional adapters with unchanged-only rollback.
- Never automate or solicit a password, credential body, Keychain secret,
  TCC response, recovery key, or passphrase. If authentication, a device/browser
  action, physical confirmation, privacy approval, reboot, or TCC interaction
  is unavoidable, pause for that owner action, then revalidate the checkpoint.
- Preserve machine-local startup bytes and unrelated settings. Never edit live
  managed markers directly.
- Do not broaden packages, change the account shell, run `chsh`, alter Terminal
  preferences, enable login items, reload an active shell or tmux server, or
  authorize plugins/connectors unless separately frozen.

Apply selected-component defaults without another question. Stop for a new
material choice or adapter state classified unsafe, ambiguous, or divergent.
