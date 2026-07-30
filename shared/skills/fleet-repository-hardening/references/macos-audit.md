# macOS audit

Record each applicable row as `pass`, `finding`, `expected`, `unavailable`, or
`unknown`; classify a failed query as `unknown`.

- Check both reverse routes independently and verify managed tunnel ownership.
- Read FileVault, SIP, Gatekeeper, firewall, stealth, updates, and backups.
- Identify unexpected wildcard listeners, especially X11 TCP.
- Check package drift, broken executable links, and active-session
  preservation.
- Verify login shell, canonical SSH fragment, tmux, remote control, and reboot
  recovery declarations without inspecting pane or transcript content.
- Record exact administrator or TCC requirements and a one-host rollback gate.
