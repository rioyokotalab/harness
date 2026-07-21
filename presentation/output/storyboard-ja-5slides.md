# Harness Evolution — 日本語5枚版 storyboard

## 中心命題

**harness は、権限・状態・環境差を暗黙に隠すのではなく、明示し、短命な証拠に束縛し、実行前後で再検証することで、ポータブル設定層から自律的な制御面へ進化した。**

対象：技術リーダー／研究基盤運用者。想定時間：8–10分。既存18枚版の
主要内容を5枚に圧縮し、詳細はspeaker notesとsource mapへ退避する。

## Slide 1 — 1つのrepositoryが7 Linux・4 Mac・2 clientsを明示的に統御する

- **目的：** 管理対象node topology、repository tree、skill invocationを一枚のcontrol pathとして示す。
- **証拠：** `90451d4:TODO.md`、7 host profiles、4 Mac acceptance、`install.sh`、repository tree、12 SKILL.md。
- **visual：** 左上に7 Linux＋transport hops＋4 opaque Macs、右上にsimplified repository tree、下にTask→client→discovery link→SKILL.md/references→dispatcher/native command→nodeの呼出しsequence。
- **notes：** transport aliasはmanaged environmentではない。Mac identity/private intentは公開しない。skillはruntime dependencyではなくagentのworking methodを指示する。
- **sources：** current TODO、profiles、README/install.sh、`.codex/AGENTS.md`、source-contract tests。

## Slide 2 — `rm -rf` 事故が「自律性＝再検証可能な権限」へ設計を変えた

- **目的：** 事故の原因、影響、containment、recovery、直接の設計応答を一本の因果列で説明する。
- **証拠：** `e5200fd` のT-171一次記録、`d726f0d` のconsolidated recovery、`238f022` のguarded-delete実装とtests。
- **visual：** 事故→停止失敗→部分復旧→guarded-deleteの4列。下段に「以前：path文字列を信頼」「以後：boundary+manifest+token+revalidation+postcheck」。
- **notes：** 影響一覧は非網羅。credentialは読んでいない。回復不能なstateは推測復元しなかった。
- **sources：** incident-rm-rf.md、historical TODO、guarded-delete skill/script/tests、client rules。

## Slide 3 — safeguardと57 focused suitesが実行をfail closedにする

- **目的：** production control pathとtest/CI feedbackを一体として説明する。
- **証拠：** AGENTS/rules、transaction engines、guarded-delete、57-suite manifest、parallel runner、phase1、CI。
- **visual：** 中央にAuthority→Observe/Plan→Apply→Revalidate→Verify/Receipt、failureをSTOP/retain/re-planへ戻すloop。上下にpolicy guardとadversarial tests、右にfocused→phase1→protected CIのtest pyramid。
- **notes：** approval promptではなく対象・authority・bytesを再検証する。各focused suiteはisolated process/logで帰属可能。CIはcredentialをpersistしない。
- **sources：** `.codex/AGENTS.md`、default.rules、run-focused-tests.py、test-phase1.sh、ci.yml、guard tests。

## Slide 4 — durable `.md` protocol がCodex–Claude協働をchat contextから分離する

- **目的：** driver/co-pilot、exchange `.md` files、staged import/receipt、state machine、resume/takeoverを一枚で示す。
- **証拠：** cowork `SKILL.md`、422-line protocol、helper、focused test、T-283/T-284 acceptance。
- **visual：** 左にCodex/Claude symmetric roles、中央にphaseごとの`.md` stack、右にsandbox→sealed stage→candidate→validated import→receipt。下に「resume from files, not chat」とtakeover rule。
- **notes：** independent passは互いの結論をblind、reconciliationでfrozen plan、target mutationはdriver only。hash/receiptはbyte関係を証明するがauthorship/honestyは証明しない。
- **sources：** cowork skill/protocol/helper/tests、acceptance audits。

## Slide 5 — 残りの進化史は「測定・回復・撤回」で現在の境界に収束した

- **目的：** 旧Slide 1/3/4/5の残余を一枚に圧縮し、全体史・測定結果・reversal・limitsを失わない。
- **証拠：** 544-commit linear history、7 stages、HPC/evaluation/backup/cowork metrics、reversal commits、current limits。
- **visual：** 上に7-stage timeline、左下にcompact evidence scoreboard、中央下に4 reversals、右下にcurrent surface＋not-claimed領域。
- **notes：** metricsはreadiness/corpus/host-specific。breadthはqualityではない。次段階はcoordination削減だがauthority/provenance/native transparencyを維持する。
- **sources：** timeline.csv、metrics.csv、audits/evaluation、reversal diffs、`90451d4:TODO.md`。
