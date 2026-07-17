HARNESS_PERSISTENT_ROOT=/mnt/nfs-03/safe/Users/rioyokota
HARNESS_CACHE_ROOT=/mnt/nfs-03/fast/Users/rioyokota/home-cache
export HARNESS_PERSISTENT_ROOT HARNESS_CACHE_ROOT

# Ubuntu's packaged user ssh-agent is started once by systemd at this stable
# runtime socket. A stable path survives tmux server/session environment age;
# identities remain entirely in the live agent and are never managed here.
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/openssh_agent
    export SSH_AUTH_SOCK
fi
