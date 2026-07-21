# Harness Evolution — 日本語5枚版 speaker notes

## Slide 1 — 1つのrepositoryが7 Linux・4 Mac・2 clientsを明示的に統御する

managed Linux environmentは`local`, `ab`, `ab2`, `ri`, `al`, `rc`, `t4`の7つ。`abci_login`は`ab`/`ab2`へのtransport、`alps_login`は`al`へのtransportであり、managed nodeとして数えない。4台のpersonal Macは個別acceptance済みだが、logical identityとprivate desired stateはpublic repositoryに置かない。

repositoryは`.codex`のpolicy/rules、`bin/harness` dispatcher、`libexec` engines、host/Mac profiles、12 shared skills、57 focused suites、docs/audits/evaluationに分かれる。`install.sh`は全skill directoryに`SKILL.md`があることと全destination collisionを先に検査し、同じsource skillをCodex、shared-agent、Claudeの3 discovery surfaceへlinkする。

invocationはtaskから始まる。clientはAGENTS/CLAUDE guidanceに従ってmatching skillを選び、`SKILL.md`を完全に読み、必要なreferenceだけを追加で読み、`harness` dispatcherまたは明示されたnative commandへ降りる。skillsはnodeを隠すruntime abstractionではなく、agentのworking methodを規定する。

## Slide 2 — `rm -rf` 事故が「自律性＝再検証可能な権限」へ設計を変えた

2026年7月15日01:41頃、temporary `HOME` を用いたplan commandのcleanupでassignmentが先に失効し、実HOMEに対する `rm -rf` が起動した。これはharness transactionではなくagent errorと一次記録に明記されている。最初のtool cancellationではchild processが残り、後続auditで発見して明示的に停止した。

harnessは検証済みbundleから、websiteのtracked pathsはHEADから復元した。一方、未commitのShellCheck workなどは失われ、一部構成は回復不能として推測復元しなかった。credential contentsは調査していない。

数時間後の`238f022`は、raw recursive `rm` のpolicy拒否とguarded-deleteを追加した。重要なのはapproval promptではなく、retained boundary、absolute targets、mode-0600 manifest、token、15-minute freshness、identity/count/size再検証、postcheckである。解釈として、この事故が自律性の意味を「自由な実行」から「対象に束縛され再検証できる短命な権限」へ変えた。

## Slide 3 — safeguardと57 focused suitesが実行をfail closedにする

実行経路はauthority/policyから始まり、value-free observationとread-only plan、explicit apply gate、target/state revalidation、native execution、doctor/receipt/unchanged-only rollbackへ進む。collision、scope drift、identity mismatch、unsupported environmentがあればSTOPし、evidenceを保持してre-planへ戻る。approval promptに依存して安全を作るのではない。

guarded-deleteはこの文法の最も明瞭な例で、canonical boundary、absolute targets、manifest/token/freshness、identity/count/size、postcheckをapply直前と直後に検証する。transaction enginesもpreimageとmanaged bytesを記録し、対象が後から編集されていればrollbackを拒否する。

57 focused suitesはmanifestからisolated subprocessとして実行され、各suiteに個別logとstatus/timeを帰属させる。visible CPUに応じて4または8 workersを使う。`tests/test-phase1.sh`がsyntax、focused suites、portable contracts、guarded cleanupを束ね、protected CIはcredentialをpersistしないUbuntu runnerでaffinity contractと完全gateを実行する。

## Slide 4 — durable `.md` protocol がCodex–Claude協働をchat contextから分離する

owner requestを受けたclientがdriver、他方がco-pilotになるrole-neutral protocolであり、Codex/Claudeのどちらも固定の上位役ではない。state machineは`planning→discussing→ready-for-execution→executing→validating→complete`の前進のみ。

`charter.md`がscope/authority/baseline、`plan.md`がinitial plan、`driver-evidence.md`と`copilot-evidence.md`がindependent experiment、`reconciliation.md`がaccepted/rejected evidenceとfrozen plan、`execution.md`と`validation.md`がdriver-only target workとacceptanceを保持する。raw logsはbounded `artifacts/`へ置き、Markdownは判断に必要な要約とpointerを保つ。

co-pilotにはlive sessionではなくpath-free projected state、charter、plan、sealed promptを含むstageだけを渡す。candidateはexternal seal、freshness、structureを検証してimportし、receipt chainへbindする。独立passの後にreciprocal critiqueを行い、driverがreconciliationを凍結してからowner goのもとtargetを一人だけが変更する。

同じroleのprocess recoveryはdisk上のstateとMarkdownを再読して最初の未検証actionから再開する。cross-product takeoverは新sessionをplanningから開始し、predecessor digestだけを引き継ぐ。これによりchat contextを唯一の状態にしない。ただしhash/receiptはbyte relationshipであり、authorshipやmodel honestyを証明しない。

## Slide 5 — 残りの進化史は「測定・回復・撤回」で現在の境界に収束した

complete historyは544 total / 544 first-parent commits、tag 0、merge commit 0。意味のある変化はProtect、Observe、Transact、Recover、Measure、Expand、Collaborateの7段階に圧縮できる。current surfaceは12 skills、43 commands、57 focused suites、7 Linux profilesだが、countは品質指標ではない。

checked-in evidenceはCPU readiness 7/7、accelerator driver/runtime 7/7、CUDA kernel 5、single-node MPI routes 5、T-181 deterministic 69/70かつsafety failure 0、backup/restore 7 primary + 7 independent generation、cowork matched median 29.69s→25.35sを示す。readinessはperformanceではなく、corpus/host-specific limitsを伴う。

成熟を示すのは追加だけではない。automatic login Git、website ownership、private Bash/tmux duplication、harness-owned native Codexを撤回した。次段階はhuman coordinationを減らすことだが、authority、provenance、native transparencyを維持する。このdeckはHPC scaling、universal agent quality、完全な事故forensics、authorship/honesty、read confidentiality、retention deletion authority、future external stateを主張しない。
