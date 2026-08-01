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
- Preserved evidence archive:
  `~/.local/state/harness/housekeeping/t303-nfs-monitor-20260724.tar.gz`
- Archive identity: 11,722,016 bytes, SHA-256
  `b5b23debd22cd2be50fcf16b46950f87e9f275abaa6187fa6d6eea60ca532302`.
- Handoff member:
  `nfs-monitor-20260724T083822+0900/HANDOFF.txt`

The original evidence directory resided on local ext4 rather than NFS, was
owned by the current user with mode 0700, and contained mode-0600 logs. The
collector itself was mode 0700. It observed fixed startup mount identities and
did not read user file contents. After collection and analysis were complete,
T-369 preserved the exact directory in the current-user, single-link,
mode-0600 archive above; gzip validation passed before guarded removal of the
original `/var/tmp` directory.

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

## Completed observation

The collector ended cleanly after exactly 86,400 seconds at 2026-07-25
08:41:19 JST. It retained 8,511 ten-second samples spanning the full day; the
lower-than-ideal 8,640 count reflects serial collection delays during the
observed stalls rather than an early stop.

Network evidence does not explain the slowdown:

- the three servers had no sustained loss and maximum observed ICMP round-trip
  times of 1.633, 1.154, and 5.080 ms;
- the NFS client recorded only five retransmissions over 148,176,545 new RPC
  calls;
- the physical NIC added no receive/transmit errors or drops.

The trace did reproduce storage-side latency:

- all three low-utilization exports on `192.168.33.30` repeatedly failed the
  collector's bounded capacity/statfs operation between 08:42 and 11:04 JST:
  112 times for `archive`, 74 for `fast`, and 44 for `safe`;
- `safe` write intervals reached 3,936 ms average RTT/execution at 11:04 JST,
  `fast` reads reached 439.5 ms at 21:55 JST, and `safe` reads reached
  148.6 ms at 09:08 JST;
- system I/O pressure later reached `some=51.65` and `full=37.91`, with up to
  seven tasks in uninterruptible sleep and 1,323 samples containing at least
  one such task.

The two 95%-full NFSv3 filesystems never failed their capacity probe. `/home`
did show a separate one-second client write-queue interval while server RTT
remained below 18 ms, and `/mnt/nfs` write RTT reached 110.5 ms. Thus capacity
may still matter for those filesystems, but it cannot explain the repeated
stalls on the 1–39%-used `192.168.33.30` exports.

## Conclusion and follow-up

The strongest supported cause is intermittent storage/NFS-service latency on
`192.168.33.30`, with at least one separate client-side queue-pressure episode
on `/home`. Local network loss and NIC faults are ruled out by the matched
trace. Local sudo is not required for further client analysis.

The next useful evidence requires the administrator of `192.168.33.30` to
correlate pool/disk latency, NFS daemon saturation, cache pressure, and system
logs for 2026-07-24 08:42–11:04 JST and the later 21:55 JST read spike.
Preserve the exact mode-0600 evidence archive unchanged until that review is
complete; do not infer a specific disk, pool, or daemon failure from the
client trace alone.

## Server-correlation gate

At 2026-07-27 19:58 JST, Local performed a batch-mode SSH preflight for the
remaining server-side review. `nas-03.yokota` resolves to `192.168.33.30`, the
same address serving `/tank/archive`, `/tank/fast`, and `/tank/safe`, and the
effective direct SSH user is `rioyokota`.

The connection failed closed at host-key verification before authentication
or execution of any remote command. Local has no saved host key for either
`nas-03.yokota` or `192.168.33.30`. SSH negotiation and a separate key scan
both observed this ED25519 fingerprint:

```text
SHA256:nxj4PfZ55OqTcVm5HReHI6IVy9MMcBQ+BbfrJfZRHes
```

Two observations over the same network path are not independent proof of
server identity. Obtain the expected fingerprint through the physical/server
console or its administrator. Do not bypass checking or accept the key from
this evidence alone.

After that independent confirmation, add only the confirmed ED25519 key and
run a bounded, read-only inventory before requesting any privileged evidence:

1. identify the operating system and storage/NFS implementation;
2. determine which unprivileged historical metrics and logs still cover
   2026-07-24 08:42–11:04 JST and 21:55 JST;
3. query pool, disk, filesystem, NFS-service, cache/memory-pressure, and system
   events only for those windows;
4. correlate timestamps with the preserved client trace and label unavailable
   evidence explicitly rather than treating it as absence.

Stop if those records require privilege or have expired. Do not change storage,
exports, services, logging, retention, or performance settings as part of
T-303.

### Access discovery

At 2026-07-27 20:10 JST, a bounded read-only service check found port 22 open
and ports 80 and 443 closed or filtered. The SSH identification string was
`SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.18`. This supports an Ubuntu
SSH-administered host and provides no browser-management path.

Value-minimized `ssh-keygen -F` queries for the exact hostname and address
found no historical trust record on Local, AB, AB2, RI, RC, T4, ABQ's two
routes, AL, Aist, Home, Office, or Riken. The queries returned fingerprints
only if present and did not inspect SSH credentials; all returned none. No
authentication was attempted.

The owner reports never having logged in to `nas-03`. The next safe step is
therefore organizational or console discovery: identify the person who
installed/administers the host, or use its physical or hypervisor console.
That independently trusted path must confirm both the host fingerprint and
the intended login account. Password guessing, first-use acceptance from the
same network path, or account recovery would be a separate administrative
operation and is not authorized by this diagnostic task.

The owner subsequently confirmed having no access to the machine. Server-side
correlation is therefore externally blocked, not disproven and not complete.
The existing client conclusion remains the strongest supported operational
result. No further login attempt is retry-safe until a responsible
administrator or trusted console independently confirms the host fingerprint
and intended account.
