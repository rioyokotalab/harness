# 日本語1枚版：スライド主張と証拠の対応

対象スナップショットは `90451d49ac96a31ca5f42044ce2f4735b8908698`
（2026-07-21）。旧5枚版の最終summary slideだけを残した。stage分類と結論は
解釈であり、数値・reversal・current surfaceとは明示的に区別する。

| Slide | 主張 | commit / path | 再現・検証 | 種別 |
| --- | --- | --- | --- | --- |
| 1 | 対象履歴は544 total / 544 first-parent、tag 0、merge commit 0で、意味のある変化はProtect・Observe・Transact・Recover・Measure・Expand・Collaborateの7段階に要約できる。 | `7f969317`→`90451d4`; `presentation/evidence/timeline.csv`; `milestones.md` | `git rev-list`; `git tag`; milestone diffs | 履歴値は事実、7段階は分類解釈 |
| 1 | checked-in evidenceはCPU readiness 7/7、accelerator driver/runtime 7/7、CUDA kernel 5、single-node MPI route 5、T-181 deterministic 69/70・safety failure 0、verified restore 7+7、cowork matched median −14.62%を示す。 | `presentation/evidence/metrics.csv`; HPC audits; T-181 results/review; backup audits; T-284 acceptance | metrics.csvのreproduction commandsとchecked-in results | 事実（readiness/corpus/host固有） |
| 1 | 成熟は追加だけでなく、automatic login Git、website ownership、private Bash/tmux duplication、harness-owned native Codexの撤回・縮小でも進んだ。 | `e52a3d0`; `f1b095c`; `4209ee8`; `d76575c` | milestone diffsとfocused tests | 事実に基づく解釈 |
| 1 | source snapshot時点のsurfaceは12 skills、43 user commands、57 focused suites、7 Linux profilesだが、これらのcountは品質指標ではない。 | `90451d4`; `shared/skills`; `bin/harness`; `tests/focused-suites.tsv`; `profiles/hosts` | source-tree inspection | 事実＋明示的限界 |
| 1 | 次段階はcoordinationを減らしつつauthority・provenance・native transparencyを保つこと。このslideはHPC scaling、universal agent quality、完全な事故forensics、authorship/honesty、read confidentiality、retention deletion authority、future external stateを主張しない。 | architecture docs; audits; evaluation limitations; `TODO.md` | source-mapとacceptance limitationの照合 | 解釈＋未主張境界 |
