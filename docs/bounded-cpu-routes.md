# Bounded scheduler-native CPU routes

[`profiles/hpc-cpu-routes.tsv`](../profiles/hpc-cpu-routes.tsv) freezes the
submission shapes already validated by the fleet readiness gates. It exists so
an agent can reconstruct and print the real native command without guessing a
billing flag, group, queue, partition, resource token, or environment route.

| Node | Native scheduler shape | Environment | Important site behavior |
|---|---|---|---|
| current (`local`) | `ybatch SCRIPT`, with `#YBATCH -r thrp_1` in the script | base | parse one Slurm ID and immediately verify it; wrapper zero alone is insufficient |
| AB | `qsub -P gag51395 -q rt_HC -l select=1 -l walltime=00:05:00 …` | `module load gcc/15.2.0` in the job | one full CPU node |
| AB2 | `qsub -P gah51624 -q rt_HC -l select=1 -l walltime=00:05:00 …` | `module load gcc/15.2.0` in the job | one full CPU node |
| RI | `sbatch --account=rkp00015 --partition=gpu --nodes=1 --ntasks=1 --cpus-per-task=1 --gres=none --time=00:05:00 …` | base | site policy still injects one GPU and 400 GiB |
| AL | `sbatch --account=g177-1 --partition=normal --nodes=1 --ntasks=1 --cpus-per-task=1 --time=00:05:00 --uenv=prgenv-gnu/25.11:v1 --view=default …` | explicit uenv | AArch64 compute |
| RC | `sbatch --account=cloud-users --partition=r340 --nodes=1 --ntasks=1 --cpus-per-task=1 --gres=none --time=00:05:00 …` | base | validated x86 CPU partition; GPU partitions differ |
| T4 | `qsub -g jh250019 -l cpu_4=1 -l h_rt=00:05:00 …` | `module load gcc/14.2.0` in the job | `-g` selects the group; `-A` does not |

Every use still requires a fresh exact-name/result collision check, current
native help or a proven script, exact one-ID parsing, and immediate owner/name
status reconciliation. Queue delay is normal and does not authorize a
replacement.

This manifest is narrowly scoped to the existing one-node, five-minute,
default-priority readiness jobs. It is not authority for a project job,
training run, GPU selection, MPI request, multi-node allocation, benchmark,
longer duration, priority change, reservation, package environment, or new
billing account. Those choices remain project- or owner-specific.
