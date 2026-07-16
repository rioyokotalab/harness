# Local multi-node MPI verification boundary

T-236 attempted the non-mutating review proposed by T-229/Q4. The installed
user-facing `sbatch` refuses direct use and points users to `ybatch`. The native
`/usr/bin/sbatch` is Slurm 25.11.6 and its complete help exposes no test-only or
verify mode. The installed `ybatch` source supports `-d`, but that branch prints
the generated script and exits before its later temporary-script unlink, so it
is not an acceptable residue-free dry run.

The underlying read-only renderer reports that `thrp_1` selects partition
`threadripper-3960x`, zero GRES, six tasks per node, and a resource comment. The
live partition contains four nodes, but neither fact proves that a two-node
request is valid under the local resource-accounting wrapper or that Open MPI
will map one rank per node.

Accordingly, the route is `blocked_no_test_only`, not validated and not absent.
Unblocking requires either a site-provided non-mutating verification interface
or a separately authorized, collision-checked two-node submission. Do not run
`ybatch -d` merely to obtain generated text, do not bypass resource accounting
with `/usr/bin/sbatch`, and do not duplicate the currently pending local jobs.
