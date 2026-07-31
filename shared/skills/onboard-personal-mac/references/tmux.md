# tmux

Run `tmux-config --host HOST --plan|--apply`. Parse configuration in isolation
without executing plugins, network access, or includes. Refuse owner-path
replacement, active-server reload, or behavior that depends on the current
interactive server.

Validate parsing and expected routing in a fresh isolated tmux server and
session. Leave every active shell and tmux server untouched.
