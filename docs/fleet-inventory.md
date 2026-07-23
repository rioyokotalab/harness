# Fleet connection inventory

This public, non-secret table is the cold-start reference for conversations
about the owner's managed systems. Logical aliases identify harness nodes;
SSH entries are the names used from `local`. Host patterns describe the
site-selected login node and may vary between connections.

| Logical alias | SSH entry or entries | Username | Global hostname | Login/local hostname | Operating system | User guide |
| --- | --- | --- | --- | --- | --- | --- |
| `local` | `login` | `rioyokota` | `login.rio.scrc.iir.isct.ac.jp` | `login-*` | Ubuntu 24.04.3 LTS, x86_64 | [Hinadori cluster](https://github.com/rioyokotalab/server-admin/wiki/How-to-use-hinadori-cluster) (private) |
| `ab` | `ab` | `aca10017by` | `as.v3.abci.ai` | `login*` | Red Hat Enterprise Linux 9.4, x86_64 | [ABCI 3.0](https://docs.abci.ai/v3/en/) |
| `ab2` | `ab2` | `aah17783cq` | `as.v3.abci.ai` | `login*` | Red Hat Enterprise Linux 9.4, x86_64 | [ABCI 3.0](https://docs.abci.ai/v3/en/) |
| `abq` | `abq`, `abq2` | `qai10412cx` | `qas.q.abci.ai` | `qes*` | Red Hat Enterprise Linux 9.4, x86_64 | [ABCI-Q](https://g-quat-abciq.github.io/abciq-docs/ja/) |
| `al` | `al` | `ryokota` | `daint.alps.cscs.ch` | `daint-*` | SUSE Linux Enterprise Server 15 SP6, aarch64 | [CSCS Alps](https://docs.cscs.ch/alps/) |
| `rc` | `rc` | `rio.yokota` | `login.cloud.r-ccs.riken.jp` | `login*` | Rocky Linux 9.8, x86_64 | [R-CCS Cloud](https://portal.cloud.r-ccs.riken.jp/) |
| `ri` | `ri` | `rku00075` | `login.rikyu.r-ccs.riken.jp` | `c00*` | Ubuntu 24.04.4 LTS, aarch64 | [RIKYU](https://docs.r-ccs.riken.jp/rikyu/en/) |
| `t4` | `t4` | `uq02038` | `login.t4.gsic.titech.ac.jp` | `login*` | Red Hat Enterprise Linux 9.4, x86_64 | [TSUBAME4](https://www.t4.cii.isct.ac.jp/docs/all/) |
| `web` | `web` (SFTP only) | `gsic0017` | `web-o3.noc.titech.ac.jp` | `sftp` | Rocky Linux 8, x86_64 | [Managed WWW service](https://www.noc.cii.isct.ac.jp/en/server-hosting-service/) |
| `aist` | `aist`, `aist2` | `rioyokota` | `localhost` | `aist` | macOS 26.5.2, arm64 | — |
| `home` | `home`, `home2` | `yokotar` | `localhost` | `home` | macOS 26.5.2, arm64 | — |
| `office` | `office`, `office2` | `yokotar` | `localhost` | `office` | macOS 26.5.2, arm64 | — |
| `riken` | `riken`, `riken2` | `yokotar` | `localhost` | `riken2` | macOS 26.5.2, arm64 | — |

The current managed control-plane scope is the original 11 nodes plus `abq`.
`web` remains a service-only alias and is not
a command, deployment, health-monitor, package, Python, or synchronization
target. The `web` OS is documented by the
[Science Tokyo NOC service specification](https://www.noc.cii.isct.ac.jp/srv/wwwsrv/)
and an [official Tokyo Tech technical document](https://www.titech.ac.jp/0/pdf/info-31935-3.pdf).
