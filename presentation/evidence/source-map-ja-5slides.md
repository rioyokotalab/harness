# 日本語5枚版：スライド主張と証拠の対応

対象スナップショットは `90451d49ac96a31ca5f42044ce2f4735b8908698`
（2026-07-21）。Slide 2は前版を固定し、他4枚をnode/repository/skill、
safeguard/test、durable cowork protocol、圧縮された全体史へ再構成した。

| Slide | 主張 | commit / path | 再現・検証 | 種別 |
| --- | --- | --- | --- | --- |
| 1 | managed Linux environmentは`local`, `ab`, `ab2`, `ri`, `al`, `rc`, `t4`の7つ。`abci_login`と`alps_login`はtransport-onlyで、4 personal Macsはprivate identityを公開せず個別acceptance済み。 | `90451d4`; `TODO.md`; `profiles/hosts/*.conf`; personal-Mac docs/schema | `find profiles/hosts`; `git show 90451d4:TODO.md` | 事実（Mac identityは非公開） |
| 1 | repositoryはpolicy/rules、dispatcher/engines、profiles、12 shared skills、57 focused suites、docs/audits/evaluationに分離される。 | `90451d4`; repository tree; focused-suite manifest | `find`; `bin/harness help`; manifest count | 事実（tree要約） |
| 1 | `install.sh`は各`shared/skills/*/SKILL.md`をCodex、shared-agent、Claudeの3 discovery surfaceへfail-closed symlinkし、task match後にclientがSKILL.mdと必要referencesを読み、`harness`またはnative commandを実行する。 | `install.sh`; `.codex/AGENTS.md`; `README.md`; skill files | installer/source-contract tests | 事実 |
| 2 | 2026-07-15 01:41頃、temporary `HOME` のスコープ切れにより cleanup が実HOMEへ解決され、agent が `rm -rf /home/rioyokota` を起動した。最初のキャンセルでは子プロセスが停止しなかった。 | `e5200fd`; historical `TODO.md`; `presentation/evidence/incident-rm-rf.md` | `git show e5200fd -- TODO.md` | 事実 |
| 2 | 部分的なHOME喪失をbundle/HEADから復旧したが、未commit作業と一部構成は回復不能として推測復元しなかった。 | `e5200fd`; `d726f0d`; historical recovery ledger | `git show d726f0d^:TODO.md` | 事実（影響一覧は非網羅） |
| 2 | 直接の設計応答として、raw recursive `rm` の拒否と、境界・manifest・token・freshness・identity/size再検証・postcheckを持つ guarded-delete が追加された。 | `238f022`; `.codex/rules/default.rules`; guarded-delete skill/script; `tests/test-guarded-delete.sh` | focused guarded-delete suite | 事実 |
| 3 | safeguardはauthority/policy、read-only plan、transaction/revalidation、unchanged-only rollback、doctor/receiptの層でfail closedし、failureはSTOP・evidence保持・re-planへ戻す。 | `.codex/AGENTS.md`; `.codex/rules/default.rules`; `libexec/harness-*`; guarded-delete skill | transaction/guarded-delete tests | 事実＋構造化解釈 |
| 3 | 57 focused suitesはmanifestからisolated processとして4/8-workerで実行され、`tests/test-phase1.sh`がsyntax・focused suites・guarded cleanup・portable gatesを束ね、protected CIがcredential-free Ubuntu runnerで実行する。 | `tests/focused-suites.tsv`; `tools/run-focused-tests.py`; `tests/test-phase1.sh`; `.github/workflows/ci.yml` | clean-tree phase-1 run | 事実 |
| 3 | testsはcollision、symlink/hardlink、token mismatch、target drift、partial inventory、repository independence、source hygieneなどをadversarialに検証する。 | focused tests; guarded-delete tests; public/source-contract tests | named focused suites | 事実 |
| 4 | coworkはrole-neutralなdriver/co-pilot protocolで、`planning→discussing→ready-for-execution→executing→validating→complete`のみを許す。 | cowork `SKILL.md`; `references/protocol.md`; helper | cowork focused test and session validator | 事実 |
| 4 | `charter.md`, `plan.md`, two evidence files, `reconciliation.md`, `execution.md`, `validation.md`がscope/evidence/frozen plan/execution/acceptanceをdurableに分担し、raw logsはbounded `artifacts/`へ退避する。 | protocol file table; helper schemas | session init/advance/validate tests | 事実 |
| 4 | blinded stageはpath-free projected state、sealed prompt、external seal、candidate、import receiptでlive sessionへの直接writeを避ける。chat contextではなくfiles/stateを再読して同一role recoveryでき、cross-product takeoverは新session＋predecessorから再計画する。 | cowork skill/protocol; T-283/T-284 audits | staged import/receipt/takeover tests | 事実（hashはauthorshipを証明しない） |
| 5 | complete historyは544 total / 544 first-parent、tag 0、merge commit 0で、七段階の進化、checked-in readiness/evaluation/recovery、重要なreversalへ圧縮できる。 | `7f969317`→`90451d4`; timeline; metrics; milestone diffs | Git history and reproduction commands | 事実＋分類解釈 |
| 5 | 現行harnessは12 skills、43 user commands、57 focused suites、7 Linux profilesを持つが、breadthは品質指標ではない。 | `90451d4`; `shared/skills`; `bin/harness`; focused-suite manifest; host profiles | source-tree inspection | 事実＋明示的限界 |
| 5 | 成熟は機能追加だけでなく、automatic Git hook、website ownership、private duplication、native-client ownershipの撤回・縮小によって進んだ。 | `e52a3d0`; `f1b095c`; `4209ee8`; `d76575c` | milestone diffs and focused tests | 事実に基づく解釈 |
| 5 | 未主張：HPC performance/scaling、universal agent quality、完全な事故forensics、model authorship/honesty、read confidentiality、retention deletion authority、future external state。 | evidence limitations; architecture docs; audit limitations | source-map and acceptance limitations | 方法上の境界 |
