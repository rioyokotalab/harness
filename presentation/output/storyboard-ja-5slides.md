# Harness Evolution — 日本語5枚版 storyboard

## 中心命題

**harness は、権限・状態・環境差を暗黙に隠すのではなく、明示し、短命な証拠に束縛し、実行前後で再検証することで、ポータブル設定層から自律的な制御面へ進化した。**

対象：技術リーダー／研究基盤運用者。想定時間：8–10分。既存18枚版の
主要内容を5枚に圧縮し、詳細はspeaker notesとsource mapへ退避する。

## Slide 1 — 「設定を配る仕組み」から「証拠で制御する仕組み」へ

- **目的：** 全体の結論と7段階の進化を一枚で提示する。
- **証拠：** root `7f969317`、最新source HEAD `7c592af`、complete first-parent history。
- **visual：** 左に中心命題、下に Protect→Observe→Transact→Recover→Measure→Expand→Collaborate のnative timeline、右に初期/現在の対比。
- **notes：** 543 commitsは活動量であり品質指標ではない。物語は意味のあるarchitectural pivotsだけを採用する。
- **sources：** `README.md`、`bin/harness`、`docs/environment-portability.md`、timeline.csv。

## Slide 2 — `rm -rf` 事故が「自律性＝再検証可能な権限」へ設計を変えた

- **目的：** 事故の原因、影響、containment、recovery、直接の設計応答を一本の因果列で説明する。
- **証拠：** `e5200fd` のT-171一次記録、`d726f0d` のconsolidated recovery、`238f022` のguarded-delete実装とtests。
- **visual：** 事故→停止失敗→部分復旧→guarded-deleteの4列。下段に「以前：path文字列を信頼」「以後：boundary+manifest+token+revalidation+postcheck」。
- **notes：** 影響一覧は非網羅。credentialは読んでいない。回復不能なstateは推測復元しなかった。
- **sources：** incident-rm-rf.md、historical TODO、guarded-delete skill/script/tests、client rules。

## Slide 3 — transaction loop が異種環境を統一せずに統御可能にした

- **目的：** 初期と現在のarchitectureを比較し、七段階を一枚のsystem modelへ統合する。
- **証拠：** `7f969317`、`fb417282`、`07351a40`、backup/fleet/Mac/cowork commits、current dispatcher。
- **visual：** 左25%に初期linear chain、右75%に Sources/Profiles/Manifests→Observe/Plan/Apply/Verify→Linux/HPC・Mac/private・Backup/Fleet・Clients/Cowork。外周に非所有境界。
- **notes：** 標準化したのはschedulerやmachineではなくcontrol grammar。private intentとsite substrateは外側に残る。
- **sources：** environment-portability、personal-macos、hpc-readiness、home-backup、cowork acceptance。

## Slide 4 — 評価・readiness・restore が「改善」を測定可能な主張に限定した

- **目的：** repositoryから再現できる成果を一枚に集約し、限界も同時に表示する。
- **証拠：** HPC JSON、T-181 JSON/review、backup acceptance、T-284 matched samples、最新Mac ledger。
- **visual：** 5 metric cards + compact readiness matrix + host-specific timing bar。各cardにscope label。
- **notes：** readiness≠performance、69/70 deterministicと70/70 substantive reviewを混同しない、timingは単一host、Mac 4/4は2026-07-21のsnapshot。
- **sources：** metrics.csv、audit JSON、evaluation results、T-284 acceptance、`7c592af:TODO.md`。

## Slide 5 — 現在の広さより、境界を縮め続ける能力が次の成熟を決める

- **目的：** current harness、重要なreversal、open questions、evidence limitsを結論としてまとめる。
- **証拠：** 12 skills / 43 commands / 57 suites / 7 Linux profiles、reversal commits、current open backup/HPC limits。
- **visual：** 左にcurrent command grammar、中央に「追加」対「撤回」の二軸、右に次段階と未主張領域。
- **notes：** automatic Git、website ownership、private duplication、native Codex ownershipを撤回した。次はhuman coordinationを減らすが、authority/provenance/native transparencyを弱めない。
- **sources：** dispatcher、focused suites、reversal diffs、TODO、source-map-ja-5slides.md。
