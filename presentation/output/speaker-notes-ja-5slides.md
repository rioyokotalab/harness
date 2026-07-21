# Harness Evolution — 日本語5枚版 speaker notes

## Slide 1 — 「設定を配る仕組み」から「証拠で制御する仕組み」へ

2026年7月14日のrootは、非機密なworking agreements、rules、skillsを既知のsymlinkでCodexへ届ける18-fileのportable layerだった。翌commitでClaudeも加わったが、machine stateは意図的に外に置かれていた。

7月21日のsource HEADでは、観測、比較、transaction、recovery、evaluation、Mac、coworkまでが一つのcontrol grammarでつながる。中心命題は、harnessが「差を消した」のではなく、権限・状態・環境差を明示して扱えるようになった、という点である。543 commitsは完全履歴の範囲を示すだけで品質の尺度ではない。

## Slide 2 — `rm -rf` 事故が「自律性＝再検証可能な権限」へ設計を変えた

2026年7月15日01:41頃、temporary `HOME` を用いたplan commandのcleanupでassignmentが先に失効し、実HOMEに対する `rm -rf` が起動した。これはharness transactionではなくagent errorと一次記録に明記されている。最初のtool cancellationではchild processが残り、後続auditで発見して明示的に停止した。

harnessは検証済みbundleから、websiteのtracked pathsはHEADから復元した。一方、未commitのShellCheck workなどは失われ、一部構成は回復不能として推測復元しなかった。credential contentsは調査していない。

数時間後の`238f022`は、raw recursive `rm` のpolicy拒否とguarded-deleteを追加した。重要なのはapproval promptではなく、retained boundary、absolute targets、mode-0600 manifest、token、15-minute freshness、identity/count/size再検証、postcheckである。解釈として、この事故が自律性の意味を「自由な実行」から「対象に束縛され再検証できる短命な権限」へ変えた。

## Slide 3 — transaction loop が異種環境を統一せずに統御可能にした

初期architectureはrepository→installer→known symlinks→client discoveryのlinear chainだった。inventoryもdesired-vs-observed comparisonもmutation verificationもなかった。

`fb417282`でvalue-free inventory/plan/doctorとlogical profilesが入り、`07351a40`以降でplan/apply/rollbackがtransactionになった。その後、guarded deletion、backup/restore、fleet fast-forward、public/private Mac、agent replacement、symmetric coworkが同じ文法へ拡張された。

ただしSlurm/PBS/AGE/modules/uenvなどのnative semantics、credential、site substrate、project runtimes、private Mac intentは外側に残る。harnessが標準化したのはmachineそのものではなく、観測・判断・実行・証拠化の手順である。

## Slide 4 — 評価・readiness・restore が「改善」を測定可能な主張に限定した

HPC auditはCPU readiness 7/7、accelerator driver/runtime 7/7、CUDA kernel 5、single-node MPI route 5を示す。これはcorrectness/readiness evidenceでありperformance/scalingではない。

T-181は70 primary runs中69 deterministic pass、safety failure 0。targeted reviewが70件をsubstantively acceptableと判断したこととは別の尺度で、candidateには採用を正当化するgainがなくbaselineを保持した。Backupは7 primaryと7 independent generationでcheck/restoreを通過。Cowork refinementは単一8-CPU-visible hostのmatched medianで29.69秒から25.35秒、14.62%減。最新HEADでは4台のMacが個別acceptance済みである。

数字はすべてscopeと限界を伴う。ここで示すのは「より良いと一般化できる」ことではなく、「何をどこまで証明したか」を追跡できるようになったこと。

## Slide 5 — 現在の広さより、境界を縮め続ける能力が次の成熟を決める

current surfaceは12 shared skills、43 user commands、57 focused suites、7 Linux profiles。観測、transaction、recovery、distribution、collaborationをplan-by-defaultとexplicit live gateで扱う。ただしsurface countは品質指標ではない。

成熟を示すのは追加だけではない。automatic login Git fetch/exit publishを撤回し、website固有ownershipを除き、private Bash/tmux duplicationをpublic engineへ戻し、native Codex ownershipをlocal installationへ返した。境界を狭める判断がcontrol planeを安全にした。

次段階はhuman coordinationを減らすこと。ただしauthority、provenance、native-system transparencyを弱めてはならない。このdeckはHPC scaling、universal agent quality、完全な事故forensics、model authorship/honesty、read confidentiality、retention deletion authority、future external stateを主張しない。
