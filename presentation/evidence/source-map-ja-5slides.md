# 日本語5枚版：スライド主張と証拠の対応

対象スナップショットは `7c592af6a9778ce24fe36b093c3bcdccb877da61`
（2026-07-21）。既存18枚版の証拠を圧縮し、`rm -rf` 事故の一次記録を追加した。

| Slide | 主張 | commit / path | 再現・検証 | 種別 |
| --- | --- | --- | --- | --- |
| 1 | harness は7日間でポータブルなポリシー配布から、明示的な権限・状態・差分を扱う証拠駆動制御面へ進化した。 | `7f969317` → `7c592af`; `README.md`; `bin/harness`; `docs/environment-portability.md` | `git log --first-parent --reverse`; `git show 7f969317:README.md`; `git show 7c592af:README.md` | 事実に基づく解釈 |
| 1 | 対象履歴は543 commits、first-parentも543、tag 0、merge commit 0。 | `7c592af`; Git object database | `git rev-list --count 7c592af`; `git rev-list --first-parent --count 7c592af`; `git tag`; `git log 7c592af --merges` | 事実（品質指標ではない） |
| 2 | 2026-07-15 01:41頃、temporary `HOME` のスコープ切れにより cleanup が実HOMEへ解決され、agent が `rm -rf /home/rioyokota` を起動した。最初のキャンセルでは子プロセスが停止しなかった。 | `e5200fd`; historical `TODO.md`; `presentation/evidence/incident-rm-rf.md` | `git show e5200fd -- TODO.md` | 事実 |
| 2 | 部分的なHOME喪失をbundle/HEADから復旧したが、未commit作業と一部構成は回復不能として推測復元しなかった。 | `e5200fd`; `d726f0d`; historical recovery ledger | `git show d726f0d^:TODO.md` | 事実（影響一覧は非網羅） |
| 2 | 直接の設計応答として、raw recursive `rm` の拒否と、境界・manifest・token・freshness・identity/size再検証・postcheckを持つ guarded-delete が追加された。 | `238f022`; `.codex/rules/default.rules`; guarded-delete skill/script; `tests/test-guarded-delete.sh` | focused guarded-delete suite | 事実 |
| 3 | 初期は repository→installer→known symlink→client discovery だったが、現在は observe→plan→apply→verify/rollback の transaction loop でLinux/HPC、Mac/private companion、backup、fleet、coworkを扱う。 | `7f969317`; `fb417282`; `07351a40`; `7c592af` | `bin/harness help`; phase-1 tests | 事実＋構造化解釈 |
| 3 | native site semantics と private intent はcontrol planeの外側に残り、標準化したのは「機械」ではなく制御文法である。 | `docs/environment-portability.md`; `docs/personal-macos.md`; `docs/hpc-readiness.md` | profile/source-contract tests | 事実に基づく解釈 |
| 4 | checked-in evidence はCPU 7/7、accelerator driver/runtime 7/7、CUDA kernel 5、single-node MPI route 5、T-181 69/70・safety failure 0、backup/restore 7+7を示す。 | HPC audit JSON; T-181 JSON; backup audit/docs | `metrics.csv` の再現command | 事実（readiness/corpus固有） |
| 4 | cowork focused suiteのmatched medianは単一8-CPU-visible host上で29.69s→25.35s（14.62%減）。 | `bb11854`; `docs/audits/t284-cowork-acceptance.md` | six sequential clean samples | 事実（host固有） |
| 4 | 最新HEADでは4台のpersonal Macが個別acceptance済み。 | `7c592af`; `TODO.md` | `git show 7c592af:TODO.md` | 事実（2026-07-21時点） |
| 5 | 現行harnessは12 skills、43 user commands、57 focused suites、7 Linux profilesを持つが、breadthは品質指標ではない。 | `7c592af`; `shared/skills`; `bin/harness`; focused-suite manifest; host profiles | original metrics script plus source-tree inspection | 事実＋明示的限界 |
| 5 | 成熟は機能追加だけでなく、automatic Git hook、website ownership、private duplication、native-client ownershipの撤回・縮小によって進んだ。 | `e52a3d0`; `f1b095c`; `4209ee8`; `d76575c` | milestone diffs and focused tests | 事実に基づく解釈 |
| 5 | 未主張：HPC performance/scaling、universal agent quality、完全な事故forensics、model authorship/honesty、read confidentiality、retention deletion authority、future external state。 | evidence limitations; architecture docs; audit limitations | source-map and acceptance limitations | 方法上の境界 |
