# Fleet connection inventory

This public, non-secret table is the cold-start reference for conversations
about the owner's managed systems. Logical aliases identify harness nodes;
SSH entries are the names used from `local`. Host patterns describe the
site-selected login node and may vary between connections.

| Logical alias | SSH entry or entries | Username | Global hostname | Login/local hostname | Operating system |
| --- | --- | --- | --- | --- | --- |
| `local` | `login` | `rioyokota` | `login.rio.scrc.iir.isct.ac.jp` | `login-*` | Ubuntu 24.04.3 LTS, x86_64 |
| `ab` | `ab` | `aca10017by` | `as.v3.abci.ai` | `login*` | Red Hat Enterprise Linux 9.4, x86_64 |
| `ab2` | `ab2` | `aah17783cq` | `as.v3.abci.ai` | `login*` | Red Hat Enterprise Linux 9.4, x86_64 |
| `abq` | `abq`, `abq2` | `qai10412cx` | `qas.q.abci.ai` | `qes*` | Red Hat Enterprise Linux 9.4, x86_64 |
| `al` | `al` | `ryokota` | `daint.alps.cscs.ch` | `daint-*` | SUSE Linux Enterprise Server 15 SP6, aarch64 |
| `rc` | `rc` | `rio.yokota` | `login.cloud.r-ccs.riken.jp` | `login*` | Rocky Linux 9.8, x86_64 |
| `ri` | `ri` | `rku00075` | `login.rikyu.r-ccs.riken.jp` | `c00*` | Ubuntu 24.04.4 LTS, aarch64 |
| `t4` | `t4` | `uq02038` | `login.t4.gsic.titech.ac.jp` | `login*` | Red Hat Enterprise Linux 9.4, x86_64 |
| `web` | `web` (SFTP only) | `gsic0017` | `web-o3.noc.titech.ac.jp` | `sftp` | Rocky Linux 8, x86_64 |
| `aist` | `aist`, `aist2` | `rioyokota` | `localhost` | `aist` | macOS 26.5.2, arm64 |
| `home` | `home`, `home2` | `yokotar` | `localhost` | `home` | macOS 26.5.2, arm64 |
| `office` | `office`, `office2` | `yokotar` | `localhost` | `office` | macOS 26.5.2, arm64 |
| `riken` | `riken`, `riken2` | `yokotar` | `localhost` | `riken2` | macOS 26.5.2, arm64 |

The current managed control-plane scope is the original 11 nodes plus `abq`
after its onboarding completes. `web` remains a service-only alias and is not
a command, deployment, health-monitor, package, Python, or synchronization
target. The `web` OS is documented by the
[Science Tokyo NOC service specification](https://www.noc.cii.isct.ac.jp/srv/wwwsrv/)
and an [official Tokyo Tech technical document](https://www.titech.ac.jp/0/pdf/info-31935-3.pdf).
