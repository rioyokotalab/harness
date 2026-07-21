#!/usr/bin/env python3
"""Build and render the dense five-slide Japanese harness-evolution deck."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

import build_deck as bd


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "presentation/output"
PPTX = OUT / "harness-evolution-ja-5slides.pptx"
RENDER_DIR = OUT / "rendered-ja-5slides"
CONTACT = OUT / "contact-sheet-ja-5slides.png"
JP_FONT = "/usr/share/fonts/opentype/ipaexfont-gothic/ipaexg.ttf"

bd.PPTX = PPTX
bd.RENDER_DIR = RENDER_DIR
bd.PPT_FONT = "Yu Gothic"
bd.FONT_REG = JP_FONT
bd.FONT_BOLD = JP_FONT
bd.FONT_ITALIC = JP_FONT


def title(slide: bd.Slide, subtitle: str) -> None:
    slide.text(0.68, 0.35, 12.0, 0.64, slide.title, size=25.5, bold=True, color="ink", min_size=21)
    slide.text(0.70, 1.00, 11.9, 0.30, subtitle, size=10.8, color="muted")


def footer(slide: bd.Slide, number: int, source: str) -> None:
    slide.line(0.68, 7.08, 12.66, 7.08, color="line", width=0.8)
    slide.text(0.70, 7.12, 11.45, 0.18, source, size=6.6, color="muted", min_size=6.0)
    slide.text(12.25, 7.10, 0.36, 0.20, str(number), size=7.5, bold=True, color="muted", align="right")


def label(slide: bd.Slide, x: float, y: float, w: float, text: str, color: str) -> None:
    slide.rect(x, y, w, 0.30, fill=bd.tint(color, 0.83), line=color, radius=0.11)
    slide.text(x + 0.06, y + 0.07, w - 0.12, 0.15, text, size=8.2, bold=True, color=color, align="center")


def metric(slide: bd.Slide, x: float, y: float, w: float, h: float, value: str, caption: str, scope: str, color: str) -> None:
    slide.rect(x, y, w, h, fill=bd.tint(color, 0.93), line=color, radius=0.14)
    slide.text(x + 0.12, y + 0.18, w - 0.24, 0.45, value, size=23, bold=True, color=color, align="center")
    slide.text(x + 0.14, y + 0.76, w - 0.28, 0.34, caption, size=10.1, bold=True, color="ink", align="center")
    slide.text(x + 0.14, y + h - 0.30, w - 0.28, 0.16, scope, size=7.0, color="muted", align="center")


def notes() -> dict[int, str]:
    return {
        1: """managed Linux environmentはlocal, ab, ab2, ri, al, rc, t4の7つ。abci_loginはab/ab2へのtransport、alps_loginはalへのtransportであり、managed nodeとして数えない。4台のpersonal Macは個別acceptance済みだが、logical identityとprivate desired stateはpublic repositoryに置かない。

repositoryは.codexのpolicy/rules、bin/harness dispatcher、libexec engines、host/Mac profiles、12 shared skills、57 focused suites、docs/audits/evaluationに分かれる。install.shは全skill directoryにSKILL.mdがあることと全destination collisionを先に検査し、同じsource skillをCodex、shared-agent、Claudeの3 discovery surfaceへlinkする。

invocationはtaskから始まる。clientはmatching skillを選び、SKILL.mdを完全に読み、必要なreferenceだけを追加で読み、harness dispatcherまたは明示されたnative commandへ降りる。skillsはnodeを隠すruntime abstractionではなく、agentのworking methodを規定する。""",
        2: """2026年7月15日01:41頃、temporary HOMEを用いたplan commandのcleanupでassignmentが先に失効し、実HOMEに対する rm -rf が起動した。これはharness transactionではなくagent errorと一次記録に明記されている。最初のtool cancellationではchild processが残り、後続auditで発見して明示的に停止した。

harnessは検証済みbundleから、websiteのtracked pathsはHEADから復元した。一方、未commitのShellCheck workなどは失われ、一部構成は回復不能として推測復元しなかった。credential contentsは調査していない。

238f022はraw recursive rmのpolicy拒否とguarded-deleteを追加した。retained boundary、absolute targets、mode-0600 manifest、token、15-minute freshness、identity/count/size再検証、postcheckが自律性を対象に束縛された短命な権限へ変えた。""",
        3: """実行経路はauthority/policyから始まり、value-free observationとread-only plan、explicit apply gate、target/state revalidation、native execution、doctor/receipt/unchanged-only rollbackへ進む。collision、scope drift、identity mismatch、unsupported environmentがあればSTOPし、evidenceを保持してre-planへ戻る。approval promptに依存して安全を作るのではない。

guarded-deleteはcanonical boundary、absolute targets、manifest/token/freshness、identity/count/size、postcheckをapply直前と直後に検証する。transaction enginesもpreimageとmanaged bytesを記録し、対象が後から編集されていればrollbackを拒否する。

57 focused suitesはmanifestからisolated subprocessとして実行され、各suiteに個別logとstatus/timeを帰属させる。visible CPUに応じて4または8 workersを使う。test-phase1.shがsyntax、focused suites、portable contracts、guarded cleanupを束ね、protected CIはcredentialをpersistしないUbuntu runnerでaffinity contractと完全gateを実行する。""",
        4: """owner requestを受けたclientがdriver、他方がco-pilotになるrole-neutral protocolであり、Codex/Claudeのどちらも固定の上位役ではない。state machineはplanning→discussing→ready-for-execution→executing→validating→completeの前進のみ。

charter.mdがscope/authority/baseline、plan.mdがinitial plan、driver-evidence.mdとcopilot-evidence.mdがindependent experiment、reconciliation.mdがaccepted/rejected evidenceとfrozen plan、execution.mdとvalidation.mdがdriver-only target workとacceptanceを保持する。raw logsはbounded artifactsへ置く。

co-pilotにはlive sessionではなくpath-free projected state、charter、plan、sealed promptを含むstageだけを渡す。candidateはexternal seal、freshness、structureを検証してimportし、receipt chainへbindする。独立passの後にreciprocal critiqueを行い、driverがreconciliationを凍結してからowner goのもとtargetを一人だけが変更する。

同じroleのprocess recoveryはdisk上のstateとMarkdownを再読して最初の未検証actionから再開する。cross-product takeoverは新sessionをplanningから開始し、predecessor digestだけを引き継ぐ。hash/receiptはbyte relationshipであり、authorshipやmodel honestyを証明しない。""",
        5: """complete historyは544 total / 544 first-parent commits、tag 0、merge commit 0。意味のある変化はProtect、Observe、Transact、Recover、Measure、Expand、Collaborateの7段階に圧縮できる。current surfaceは12 skills、43 commands、57 focused suites、7 Linux profilesだが、countは品質指標ではない。

checked-in evidenceはCPU readiness 7/7、accelerator driver/runtime 7/7、CUDA kernel 5、single-node MPI routes 5、T-181 deterministic 69/70かつsafety failure 0、backup/restore 7 primary + 7 independent generation、cowork matched median 29.69s→25.35sを示す。readinessはperformanceではなく、corpus/host-specific limitsを伴う。

成熟を示すのは追加だけではない。automatic login Git、website ownership、private Bash/tmux duplication、harness-owned native Codexを撤回した。次段階はhuman coordinationを減らすことだが、authority、provenance、native transparencyを維持する。このdeckはHPC scaling、universal agent quality、完全な事故forensics、authorship/honesty、read confidentiality、retention deletion authority、future external stateを主張しない。""",
    }


def build_slides() -> list[bd.Slide]:
    n = notes()
    slides: list[bd.Slide] = []

    # Slide 1
    s = bd.Slide(
        "1つのrepositoryが7 Linux・4 Mac・2 clientsを明示的に統御する",
        "90451d4:TODO.md • profiles/ • install.sh • shared/skills/ • repository tree",
        notes=n[1],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "node topology × repository tree × skill invocation")
    # Managed topology
    s.rect(0.52, 1.38, 6.05, 3.93, fill="white", line="blue", radius=0.15)
    label(s, 0.78, 1.62, 1.62, "MANAGED TOPOLOGY", "blue")
    s.ellipse(2.80, 2.02, 1.38, 0.76, fill="navy", line="navy")
    s.text(2.94, 2.24, 1.10, 0.19, "local", size=12.5, bold=True, color="white", align="center")
    s.text(2.94, 2.48, 1.10, 0.14, "controller + node", size=6.7, color="gray2", align="center")
    groups = [
        (0.78, 2.10, 1.62, 0.82, "ABCI", "ab • ab2", "blue"),
        (0.78, 3.18, 1.62, 0.72, "RIKEN", "ri", "cyan"),
        (2.66, 3.18, 1.62, 0.72, "CSCS", "al", "teal"),
        (4.54, 2.10, 1.62, 0.82, "R-CCS", "rc", "violet"),
        (4.54, 3.18, 1.62, 0.72, "T4", "t4", "amber"),
    ]
    for x, y, w, h, head, body, c in groups:
        s.rect(x, y, w, h, fill=bd.tint(c, 0.90), line=c, radius=0.11)
        s.text(x + 0.10, y + 0.13, w - 0.20, 0.18, head, size=9.2, bold=True, color=c, align="center")
        s.text(x + 0.10, y + 0.43, w - 0.20, 0.16, body, size=8.4, color="ink", align="center")
        s.line(3.49, 2.80, x + w / 2, y - 0.03 if y > 2.9 else y + h + 0.03, color="gray2", width=0.8)
    s.text(0.87, 2.88, 1.44, 0.15, "via abci_login (transport)", size=6.4, color="muted", align="center")
    s.text(2.74, 3.95, 1.46, 0.15, "via alps_login (transport)", size=6.4, color="muted", align="center")
    s.rect(1.36, 4.27, 4.32, 0.70, fill=bd.tint("magenta", 0.91), line="magenta", radius=0.12)
    s.text(1.56, 4.43, 3.92, 0.21, "Personal Mac × 4 — individually accepted", size=9.4, bold=True, color="magenta", align="center")
    s.text(1.56, 4.72, 3.92, 0.13, "opaque identity • private intent outside public Git", size=6.6, color="muted", align="center")
    # Repository tree
    s.rect(6.78, 1.38, 6.03, 3.93, fill="white", line="teal", radius=0.15)
    label(s, 7.04, 1.62, 1.54, "REPOSITORY TREE", "teal")
    s.text(7.06, 2.05, 1.35, 0.22, "harness/", size=12.5, bold=True, color="ink")
    tree_rows = [
        (".codex/", "policy • rules", "blue"),
        ("bin/ → libexec/", "dispatcher • engines", "teal"),
        ("profiles/", "7 Linux • public Mac schema", "cyan"),
        ("shared/skills/", "12 × SKILL.md + refs/scripts", "violet"),
        ("tests/", "57 focused • phase1 • CI", "green"),
        ("docs/audits + evaluation/", "evidence • results • limits", "amber"),
    ]
    for i, (path, role, c) in enumerate(tree_rows):
        y = 2.40 + i * 0.43
        s.line(7.16, y + 0.10, 7.45, y + 0.10, color="gray2", width=0.9)
        s.text(7.54, y, 2.25, 0.20, path, size=8.6, bold=True, color=c)
        s.text(9.78, y, 2.66, 0.20, role, size=7.7, color="muted")
    s.rect(7.08, 4.98, 5.39, 0.20, fill="gray", line="gray2", radius=0.07, dash=True)
    s.text(7.24, 5.02, 5.07, 0.11, "secrets • live state • site substrate are not repository payload", size=6.2, color="muted", align="center")
    # Invocation flow
    label(s, 0.58, 5.57, 1.34, "SKILL INVOCATION", "violet")
    invoke = [
        ("Owner task", "blue"), ("Codex / Claude", "cyan"),
        ("discovery links", "teal"), ("match + read\nSKILL.md / refs", "violet"),
        ("harness /\nnative command", "amber"), ("exact node", "green"),
    ]
    for i, (text_value, c) in enumerate(invoke):
        x = 0.58 + i * 2.08
        s.rect(x, 6.00, 1.73, 0.56, fill=bd.tint(c, 0.89), line=c, radius=0.11)
        s.text(x + 0.08, 6.14, 1.57, 0.24, text_value, size=8.0, bold=True, color=c, align="center")
        if i < 5:
            s.line(x + 1.75, 6.28, x + 2.03, 6.28, color="darkgray", width=1.1, arrow="end")
    s.text(3.04, 6.70, 7.24, 0.15, "install.sh: preflight all collisions → link each skill to .codex / .agents / .claude", size=7.1, color="muted", align="center")
    footer(s, 1, "90451d4:TODO.md • profiles/hosts • install.sh • .codex/AGENTS.md • shared/skills • focused-suites.tsv")
    slides.append(s)

    # Slide 2
    s = bd.Slide(
        "rm -rf 事故が「自律性＝再検証可能な権限」へ設計を変えた",
        "e5200fd • d726f0d • 238f022 • incident-rm-rf.md",
        notes=n[2],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "事故 → containment → 部分復旧 → architectural response")
    cards = [
        ("01:41  原因", "temporary HOME の\nscope終了後に cleanup\n→ 実HOMEへ解決", "red"),
        ("停止の失敗", "最初のcancelでは\nchild processが残存\n→ audit後に明示停止", "amber"),
        ("影響と復旧", "HOMEを部分喪失\nbundle / HEADから復旧\n未commit作業は消失", "violet"),
        ("設計応答", "raw recursive rmを拒否\nguarded plan / apply\n境界と証拠を再検証", "green"),
    ]
    for i, (head, body, c) in enumerate(cards):
        x = 0.65 + i * 3.14
        s.rect(x, 1.48, 2.88, 2.20, fill=bd.tint(c, 0.94), line=c, radius=0.15)
        label(s, x + 0.20, 1.72, 1.34, "FACT", c)
        s.text(x + 0.20, 2.13, 2.48, 0.33, head, size=14.1, bold=True, color=c, align="center")
        s.text(x + 0.20, 2.70, 2.48, 0.70, body, size=10.5, color="ink", align="center")
        if i < 3:
            s.line(x + 2.90, 2.57, x + 3.10, 2.57, color="darkgray", width=1.3, arrow="end")
    s.text(0.72, 4.02, 2.00, 0.28, "BEFORE", size=10, bold=True, color="red")
    s.rect(0.72, 4.34, 2.20, 1.55, fill=bd.tint("red", 0.95), line="red", radius=0.14)
    s.text(0.90, 4.66, 1.84, 0.30, "path文字列を信頼", size=13.0, bold=True, color="red", align="center")
    s.text(0.90, 5.18, 1.84, 0.38, "cleanup targetが\nscopeに依存", size=9.4, color="muted", align="center")
    s.line(3.10, 5.10, 3.68, 5.10, color="darkgray", width=1.8, arrow="end")
    controls = [
        ("保持境界", "blue"), ("絶対target", "cyan"), ("manifest", "teal"),
        ("token + 15分", "amber"), ("identity / size", "violet"), ("postcheck", "green"),
    ]
    for i, (text_value, c) in enumerate(controls):
        x = 3.82 + (i % 3) * 1.72
        y = 4.34 + (i // 3) * 0.82
        s.rect(x, y, 1.52, 0.62, fill=bd.tint(c, 0.88), line=c, radius=0.12)
        s.text(x + 0.08, y + 0.19, 1.36, 0.18, text_value, size=8.8, bold=True, color=c, align="center")
    s.rect(9.25, 4.34, 3.38, 1.55, fill="navy", line="navy", radius=0.14)
    label(s, 9.52, 4.58, 1.45, "INTERPRETATION", "violet")
    s.text(9.52, 5.10, 2.84, 0.46, "自律性を「自由な実行」から\n対象に束縛された短命な権限へ", size=10.2, bold=True, color="white", align="center")
    s.rect(0.72, 6.22, 11.90, 0.48, fill="gray", line="gray2", radius=0.10, dash=True)
    s.text(0.94, 6.35, 11.46, 0.18, "限界：影響一覧は非網羅。credential contentsは未調査。回復不能stateは推測復元しなかった。", size=8.1, color="muted", align="center")
    footer(s, 2, "e5200fd: historical TODO/T-171 • d726f0d: recovery consolidation • 238f022: guard + tests")
    slides.append(s)

    # Slide 3
    s = bd.Slide(
        "safeguardと57 focused suitesが実行をfail closedにする",
        "policy → plan → transaction → revalidation → evidence → protected CI",
        notes=n[3],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "failureはSTOPし、evidenceを残し、同じscopeをre-planする")
    # Policy guard
    s.rect(0.62, 1.42, 8.34, 0.62, fill="navy", line="navy", radius=0.12)
    label(s, 0.84, 1.58, 1.18, "POLICY", "blue")
    s.text(2.20, 1.62, 6.46, 0.18, "AGENTS authority • exec rules • skill-specific boundaries • no silent fallback", size=8.6, bold=True, color="white", align="center")
    # Runtime flow
    flow = [
        ("AUTHORITY", "scope / owner go", "blue"),
        ("OBSERVE + PLAN", "value-free / no write", "cyan"),
        ("APPLY", "explicit live gate", "teal"),
        ("REVALIDATE", "identity / bytes / drift", "amber"),
        ("VERIFY", "doctor / receipt / rollback", "green"),
    ]
    for i, (head, body, c) in enumerate(flow):
        x = 0.62 + i * 1.73
        s.rect(x, 2.36, 1.48, 1.06, fill=bd.tint(c, 0.90), line=c, radius=0.12)
        s.text(x + 0.08, 2.57, 1.32, 0.20, head, size=8.4, bold=True, color=c, align="center")
        s.text(x + 0.08, 2.94, 1.32, 0.24, body, size=6.8, color="muted", align="center")
        if i < 4:
            s.line(x + 1.50, 2.89, x + 1.69, 2.89, color="darkgray", width=1.1, arrow="end")
    guard_chips = [
        ("collision refusal", "blue"), ("preimage + checksum", "teal"),
        ("manifest + token", "amber"), ("unchanged-only rollback", "violet"),
    ]
    for i, (text_value, c) in enumerate(guard_chips):
        x = 0.78 + i * 2.02
        s.rect(x, 3.70, 1.76, 0.48, fill=bd.tint(c, 0.91), line=c, radius=0.10)
        s.text(x + 0.08, 3.83, 1.60, 0.16, text_value, size=7.4, bold=True, color=c, align="center")
    # Failure loop
    s.rect(0.62, 4.52, 8.34, 0.88, fill=bd.tint("red", 0.95), line="red", radius=0.13)
    label(s, 0.86, 4.79, 0.94, "FAIL", "red")
    s.text(2.00, 4.73, 6.54, 0.24, "STOP • preserve exact error/log/state • classify retry safety • re-plan", size=9.5, bold=True, color="red", align="center")
    s.line(4.82, 4.50, 4.82, 4.20, color="red", width=1.2, arrow="end")
    s.rect(0.62, 5.72, 8.34, 0.76, fill="white", line="violet", radius=0.12, dash=True)
    s.text(0.88, 5.90, 7.82, 0.18, "Adversarial cases: protected root • symlink/hardlink • token mismatch • target drift • partial inventory • source leakage", size=7.7, color="violet", align="center")
    s.text(0.88, 6.20, 7.82, 0.14, "tests use isolated temporary state and guarded cleanup; a failure is attributable to one suite log", size=6.6, color="muted", align="center")
    # Test pyramid
    s.rect(9.24, 1.42, 3.48, 5.06, fill="white", line="green", radius=0.15)
    label(s, 9.50, 1.68, 1.22, "TEST PATH", "green")
    tests = [
        ("57 focused suites", "isolated subprocess + log", "cyan", 2.25, 2.92),
        ("parallel runner", "4 / 8 workers by visible CPU", "teal", 3.21, 2.62),
        ("test-phase1.sh", "syntax + focused + portable + cleanup", "violet", 4.17, 2.32),
        ("protected CI", "Ubuntu • no persisted credentials", "green", 5.13, 2.02),
    ]
    for head, body, c, y, w in tests:
        x = 10.98 - w / 2
        s.rect(x, y, w, 0.68, fill=bd.tint(c, 0.90), line=c, radius=0.11)
        s.text(x + 0.08, y + 0.12, w - 0.16, 0.18, head, size=8.8, bold=True, color=c, align="center")
        s.text(x + 0.08, y + 0.39, w - 0.16, 0.14, body, size=6.4, color="muted", align="center")
        if y < 5.0:
            s.line(10.98, y + 0.69, 10.98, y + 0.94, color="gray2", width=1.0, arrow="end")
    s.text(9.64, 6.04, 2.68, 0.18, "PASS = same contract at every layer", size=7.4, bold=True, color="green", align="center")
    footer(s, 3, ".codex/AGENTS.md • default.rules • transaction/guard tests • focused-suites.tsv • run-focused-tests.py • phase1 • ci.yml")
    slides.append(s)

    # Slide 4
    s = bd.Slide(
        "durable `.md` protocol がCodex–Claude協働をchat contextから分離する",
        "symmetric roles • blinded evidence • sealed stage • frozen plan • driver-only execution",
        notes=n[4],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "会話はtransport、Markdownとstateがdurable source of truth")
    # Symmetric clients
    s.rect(0.55, 1.42, 2.34, 4.73, fill="white", line="blue", radius=0.15)
    label(s, 0.80, 1.68, 1.28, "SYMMETRIC", "blue")
    s.rect(0.84, 2.20, 1.76, 0.82, fill=bd.tint("blue", 0.88), line="blue", radius=0.12)
    s.text(0.98, 2.40, 1.48, 0.22, "Codex", size=13.2, bold=True, color="blue", align="center")
    s.text(0.98, 2.70, 1.48, 0.14, "driver ↔ co-pilot", size=6.8, color="muted", align="center")
    s.line(1.72, 3.06, 1.72, 3.35, color="darkgray", width=1.1, arrow="both")
    s.rect(0.84, 3.39, 1.76, 0.82, fill=bd.tint("violet", 0.88), line="violet", radius=0.12)
    s.text(0.98, 3.59, 1.48, 0.22, "Claude", size=13.2, bold=True, color="violet", align="center")
    s.text(0.98, 3.89, 1.48, 0.14, "co-pilot ↔ driver", size=6.8, color="muted", align="center")
    s.text(0.82, 4.65, 1.80, 0.46, "同一baseline\n別sandbox\n独立passは相互blind", size=8.0, color="ink", align="center")
    s.rect(0.82, 5.40, 1.80, 0.44, fill=bd.tint("red", 0.94), line="red", radius=0.09)
    s.text(0.92, 5.53, 1.60, 0.15, "target write = driver only", size=7.0, bold=True, color="red", align="center")
    # Durable file protocol
    s.rect(3.10, 1.42, 5.66, 4.73, fill="white", line="teal", radius=0.15)
    label(s, 3.36, 1.68, 1.56, "DURABLE SESSION", "teal")
    s.rect(7.18, 1.67, 1.24, 0.34, fill=bd.tint("teal", 0.88), line="teal", radius=0.08)
    s.text(7.26, 1.76, 1.08, 0.14, "state.json", size=7.3, bold=True, color="teal", align="center")
    phases = [
        ("PLAN", "charter.md", "plan.md", "blue"),
        ("DISCUSS", "driver-evidence.md", "copilot-evidence.md", "violet"),
        ("FREEZE", "reconciliation.md", "accepted / rejected + gates", "teal"),
        ("EXECUTE", "execution.md", "driver-only target steps", "amber"),
        ("VALIDATE", "validation.md", "outcome + residual risks", "green"),
    ]
    for i, (phase, file1, file2, c) in enumerate(phases):
        y = 2.18 + i * 0.70
        s.rect(3.38, y, 1.06, 0.48, fill=bd.tint(c, 0.86), line=c, radius=0.09)
        s.text(3.46, y + 0.14, 0.90, 0.16, phase, size=7.4, bold=True, color=c, align="center")
        s.rect(4.65, y, 1.75, 0.48, fill="light", line=c, radius=0.09)
        s.text(4.73, y + 0.14, 1.59, 0.16, file1, size=7.2, bold=True, color="ink", align="center")
        s.rect(6.61, y, 1.83, 0.48, fill="light", line="gray2", radius=0.09)
        s.text(6.69, y + 0.11, 1.67, 0.22, file2, size=6.6, color="muted", align="center")
        if i < 4:
            s.line(3.91, y + 0.49, 3.91, y + 0.68, color="gray2", width=0.9, arrow="end")
    s.text(3.46, 5.81, 4.84, 0.16, "raw bulky logs → bounded artifacts/ • decisions stay concise in Markdown", size=6.8, color="muted", align="center")
    # Staged exchange
    s.rect(8.98, 1.42, 3.80, 4.73, fill="white", line="magenta", radius=0.15)
    label(s, 9.24, 1.68, 1.42, "STAGED EXCHANGE", "magenta")
    stage_steps = [
        ("driver-only prompt", "blue"),
        ("path-free state + inputs", "cyan"),
        ("external seal", "amber"),
        ("candidate evidence", "violet"),
        ("validate + import", "teal"),
        ("receipt chain", "green"),
    ]
    for i, (text_value, c) in enumerate(stage_steps):
        y = 2.16 + i * 0.57
        s.rect(9.46, y, 2.82, 0.40, fill=bd.tint(c, 0.90), line=c, radius=0.09)
        s.text(9.56, y + 0.11, 2.62, 0.15, text_value, size=7.3, bold=True, color=c, align="center")
        if i < 5:
            s.line(10.87, y + 0.41, 10.87, y + 0.55, color="gray2", width=0.8, arrow="end")
    s.text(9.30, 5.72, 3.16, 0.20, "no live-session write grant during discussion", size=6.8, color="red", align="center")
    # Context-independent recovery band
    s.rect(0.55, 6.36, 12.23, 0.50, fill="navy", line="navy", radius=0.11)
    s.text(0.82, 6.49, 3.54, 0.18, "same-role restart → state + .md を再読してresume", size=7.5, color="white", align="center")
    s.text(4.50, 6.49, 4.00, 0.18, "CHAT ≠ SOURCE OF TRUTH", size=8.7, bold=True, color="cyan", align="center")
    s.text(8.62, 6.49, 3.88, 0.18, "cross-product takeover → NEW session + predecessor", size=7.5, color="white", align="center")
    footer(s, 4, "codex-claude-cowork/SKILL.md • references/protocol.md • cowork-session helper • T-283/T-284 • focused tests")
    slides.append(s)

    # Slide 5
    s = bd.Slide(
        "残りの進化史は「測定・回復・撤回」で現在の境界に収束した",
        "7 stages • checked-in evidence • reversals • current surface • limits",
        notes=n[5],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "追加した機能より、何を証明し、何を戻し、何を所有しないか")
    # Seven-stage history
    s.line(0.72, 1.86, 12.56, 1.86, color="gray2", width=1.0)
    stage_data = [
        ("守る", "Policy", "blue"), ("観る", "Observe", "cyan"),
        ("動かす", "Transact", "teal"), ("戻す", "Recover", "amber"),
        ("測る", "Measure", "violet"), ("広げる", "Expand", "magenta"),
        ("協働", "Cowork", "green"),
    ]
    for i, (jp, en, c) in enumerate(stage_data):
        x = 0.58 + i * 1.70
        s.ellipse(x + 0.58, 1.72, 0.26, 0.26, fill=c, line=c)
        s.rect(x, 2.08, 1.42, 0.62, fill=bd.tint(c, 0.88), line=c, radius=0.10)
        s.text(x + 0.07, 2.21, 1.28, 0.18, jp, size=9.2, bold=True, color=c, align="center")
        s.text(x + 0.07, 2.46, 1.28, 0.12, en, size=6.2, color="muted", align="center")
    s.text(10.62, 1.42, 1.92, 0.18, "544 / 544 first-parent", size=7.1, bold=True, color="ink", align="right")
    s.text(10.62, 1.62, 1.92, 0.14, "0 tags • 0 merges", size=6.4, color="muted", align="right")
    # Evidence scoreboard
    s.rect(0.55, 2.98, 4.12, 3.46, fill="white", line="teal", radius=0.15)
    label(s, 0.80, 3.20, 1.46, "EVIDENCE", "teal")
    evidence = [
        ("7/7", "CPU", "cyan"), ("7/7", "Accel drv/runtime", "teal"),
        ("5", "CUDA kernel", "violet"), ("5", "MPI routes", "amber"),
        ("69/70", "T-181 deterministic", "violet"), ("0", "safety failures", "green"),
        ("7+7", "verified restore", "green"), ("−14.62%", "cowork median", "blue"),
    ]
    for i, (value, caption, c) in enumerate(evidence):
        x = 0.80 + (i % 2) * 1.86
        y = 3.72 + (i // 2) * 0.61
        s.rect(x, y, 1.68, 0.48, fill=bd.tint(c, 0.92), line=c, radius=0.08)
        s.text(x + 0.07, y + 0.10, 0.58, 0.18, value, size=8.4, bold=True, color=c, align="center")
        s.text(x + 0.66, y + 0.10, 0.94, 0.20, caption, size=6.4, color="muted", align="center")
    s.text(0.82, 6.20, 3.58, 0.14, "readiness / corpus / host-specific — not universal performance", size=6.3, color="muted", align="center")
    # Reversals
    s.rect(4.88, 2.98, 4.04, 3.46, fill="white", line="violet", radius=0.15)
    label(s, 5.14, 3.20, 1.34, "REVERSALS", "violet")
    reversals = [
        ("login fetch / exit publish", "explicit Git operations", "e52a3d0"),
        ("website ownership", "repository independence", "f1b095c"),
        ("private Bash / tmux", "public engine + private SSH", "4209ee8"),
        ("harness-owned Codex", "local native client + wrapper", "d76575c"),
    ]
    for i, (before, after, sha) in enumerate(reversals):
        y = 3.76 + i * 0.55
        s.text(5.12, y, 1.24, 0.22, before, size=6.6, bold=True, color="red", align="right")
        s.line(6.45, y + 0.11, 6.72, y + 0.11, color="gray2", width=0.9, arrow="end")
        s.text(6.82, y, 1.48, 0.22, after, size=6.6, bold=True, color="green")
        s.text(8.32, y + 0.03, 0.38, 0.12, sha, size=4.9, color="muted", align="right")
    s.rect(5.18, 6.02, 3.44, 0.26, fill=bd.tint("violet", 0.92), line="violet", radius=0.07)
    s.text(5.36, 6.09, 3.08, 0.12, "成熟 = 追加 + 回復 + 縮小 + 拒否", size=7.4, bold=True, color="violet", align="center")
    # Current boundary and limits
    s.rect(9.13, 2.98, 3.65, 3.46, fill="white", line="amber", radius=0.15)
    label(s, 9.39, 3.20, 1.46, "CURRENT / LIMITS", "amber")
    counts = [("12", "skills", "violet"), ("43", "commands", "teal"), ("57", "suites", "green"), ("7", "Linux profiles", "cyan")]
    for i, (value, caption, c) in enumerate(counts):
        x = 9.42 + (i % 2) * 1.50
        y = 3.70 + (i // 2) * 0.66
        s.rect(x, y, 1.30, 0.52, fill=bd.tint(c, 0.92), line=c, radius=0.09)
        s.text(x + 0.08, y + 0.10, 0.42, 0.20, value, size=9.8, bold=True, color=c, align="center")
        s.text(x + 0.52, y + 0.12, 0.70, 0.16, caption, size=6.4, color="muted", align="center")
    s.text(9.44, 5.02, 3.02, 0.34, "NEXT: coordination ↓\nauthority / provenance / native transparency = keep", size=6.2, bold=True, color="ink", align="center")
    s.line(9.48, 5.44, 12.44, 5.44, color="line", width=0.9)
    s.text(9.44, 5.62, 3.02, 0.16, "NOT CLAIMED", size=7.2, bold=True, color="red", align="center")
    s.text(9.48, 5.88, 2.94, 0.32, "HPC scaling • universal quality • full forensics\nauthorship/honesty • confidentiality • future state", size=6.2, color="muted", align="center")
    s.rect(0.55, 6.60, 12.23, 0.28, fill="navy", line="navy", radius=0.08)
    s.text(0.82, 6.67, 11.69, 0.13, "結論：強い自律性は、広い権限ではなく、狭く説明可能で再検証される権限から生まれる。", size=7.8, bold=True, color="white", align="center")
    footer(s, 5, "timeline.csv • metrics.csv • audit/evaluation results • reversal commits • 90451d4:TODO.md • evidence limits")
    slides.append(s)
    return slides


def contact_sheet(slides: list[bd.Slide]) -> None:
    thumbs: list[Image.Image] = []
    for i in range(1, len(slides) + 1):
        image = Image.open(RENDER_DIR / f"slide-{i:02d}.png").convert("RGB")
        image.thumbnail((576, 324), Image.Resampling.LANCZOS)
        thumbs.append(image.copy())
    cols = 2
    rows = math.ceil(len(thumbs) / cols)
    sheet = Image.new("RGB", (cols * 596, rows * 354), (235, 239, 246))
    draw = ImageDraw.Draw(sheet)
    for i, image in enumerate(thumbs):
        x = (i % cols) * 596 + 10
        y = (i // cols) * 354 + 10
        sheet.paste(image, (x, y))
        draw.text((x, y + 327), f"Slide {i + 1}", font=bd.font(8, bold=True), fill=bd.rgb("muted"))
    sheet.save(CONTACT)


def main() -> int:
    slides = build_slides()
    if len(slides) != 5:
        raise SystemExit(f"expected 5 slides, got {len(slides)}")
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    warnings: list[str] = []
    for i, slide in enumerate(slides, 1):
        warnings.extend(
            f"slide {i}: {warning}"
            for warning in bd.render_slide(slide, RENDER_DIR / f"slide-{i:02d}.png")
        )
    bd.build_pptx(slides)
    contact_sheet(slides)
    errors = bd.verify_pptx(slides)
    if warnings:
        print("RENDER WARNINGS")
        print("\n".join(warnings))
    if errors:
        print("PPTX ERRORS")
        print("\n".join(errors))
    print(
        f"slides={len(slides)} pptx={PPTX} size={PPTX.stat().st_size} "
        f"render_warnings={len(warnings)} errors={len(errors)}"
    )
    return 0 if not warnings and not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
