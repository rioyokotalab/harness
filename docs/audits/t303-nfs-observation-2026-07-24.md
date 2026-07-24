# T-303 NFS client observation

## Purpose

Capture a 24-hour, read-only client trace that can distinguish intermittent
NFS latency from client pressure and network loss without adding load to the
measured filesystems or requiring administrator access.

## Initial evidence

At 2026-07-24 08:21–08:26 JST, Local showed:

- no CPU, memory, or I/O pressure;
- no NFS RPC retransmissions across approximately 319 million calls;
- sub-millisecond ICMP latency and no loss to all three NFS servers;
- current `/home` NFS operation latency near 0.2–1 ms;
- direct reads from an existing repository pack at approximately
  410–435 MiB/s;
- cached repository metadata operations completing in milliseconds;
- `/home` and `/mnt/nfs` at 95% capacity, while the three NFSv4 project
  exports were between 1% and 38% capacity.

The reported extreme slowdown was not active during the baseline. Capacity,
intermittent server load, uncached write allocation, and workload-specific
metadata patterns therefore remain hypotheses rather than conclusions.

## Monitor

- Unit: `nfs-io-monitor-20260724T083822.service`
- Start: 2026-07-24 08:41:19 JST
- Scheduled end: 2026-07-25 08:41:19 JST
- Local evidence:
  `/var/tmp/nfs-monitor-20260724T083822+0900`
- Handoff:
  `/var/tmp/nfs-monitor-20260724T083822+0900/HANDOFF.txt`

The evidence directory resides on local ext4 rather than NFS, is owned by the
current user with mode 0700, and contains mode-0600 logs. The collector itself
is mode 0700. It observes fixed startup mount identities and does not read user
file contents.

Every ten seconds it records per-mount NFS interval statistics, load, memory,
pressure-stall information, aggregate uninterruptible-sleep counts, server
reachability, NIC counters, TCP/IP counters, aggregate NFS client counters,
and capacity. It records full per-operation mount statistics every five
minutes.

Status:

```sh
systemctl --user status nfs-io-monitor-20260724T083822.service --no-pager
```

Stop early only if required:

```sh
systemctl --user stop nfs-io-monitor-20260724T083822.service
```

## Limits and next action

The user manager has `Linger=no`. The monitor survives the launching command
and ordinary shell exit while another login session remains, but can stop if
all sessions for the user disappear. It cannot observe NFS server pools,
disks, caches, NFS daemons, switches, or privileged kernel diagnostics.

After the scheduled end, verify clean completion and correlate every latency
spike across the collected client, network, and capacity series. Request
server-side or local administrator evidence only for intervals the client
trace cannot explain.
