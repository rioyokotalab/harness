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
        1: """2026年7月14日のrootは、非機密なworking agreements、rules、skillsを既知のsymlinkでCodexへ届ける18-fileのportable layerだった。翌commitでClaudeも加わったが、machine stateは意図的に外に置かれていた。

7月21日のsource HEADでは、観測、比較、transaction、recovery、evaluation、Mac、coworkまでが一つのcontrol grammarでつながる。中心命題は、harnessが「差を消した」のではなく、権限・状態・環境差を明示して扱えるようになった、という点である。543 commitsは完全履歴の範囲を示すだけで品質の尺度ではない。""",
        2: """2026年7月15日01:41頃、temporary HOMEを用いたplan commandのcleanupでassignmentが先に失効し、実HOMEに対する rm -rf が起動した。これはharness transactionではなくagent errorと一次記録に明記されている。最初のtool cancellationではchild processが残り、後続auditで発見して明示的に停止した。

harnessは検証済みbundleから、websiteのtracked pathsはHEADから復元した。一方、未commitのShellCheck workなどは失われ、一部構成は回復不能として推測復元しなかった。credential contentsは調査していない。

238f022はraw recursive rmのpolicy拒否とguarded-deleteを追加した。retained boundary、absolute targets、mode-0600 manifest、token、15-minute freshness、identity/count/size再検証、postcheckが自律性を対象に束縛された短命な権限へ変えた。""",
        3: """初期architectureはrepository→installer→known symlinks→client discoveryのlinear chainだった。inventoryもdesired-vs-observed comparisonもmutation verificationもなかった。

fb417282でvalue-free inventory/plan/doctorとlogical profilesが入り、07351a40以降でplan/apply/rollbackがtransactionになった。その後、guarded deletion、backup/restore、fleet fast-forward、public/private Mac、agent replacement、symmetric coworkが同じ文法へ拡張された。

Slurm/PBS/AGE/modules/uenvなどのnative semantics、credential、site substrate、project runtimes、private Mac intentは外側に残る。標準化したのはmachineではなく、観測・判断・実行・証拠化の手順である。""",
        4: """HPC auditはCPU readiness 7/7、accelerator driver/runtime 7/7、CUDA kernel 5、single-node MPI route 5を示す。これはcorrectness/readiness evidenceでありperformance/scalingではない。

T-181は70 primary runs中69 deterministic pass、safety failure 0。targeted reviewの70/70 substantive acceptanceとは別の尺度である。Backupは7 primaryと7 independent generationでcheck/restoreを通過。Cowork refinementは単一8-CPU-visible hostのmatched medianで29.69秒から25.35秒、14.62%減。最新HEADでは4台のMacが個別acceptance済み。

数字はscopeと限界を伴う。一般的な優越性ではなく、何をどこまで証明したかを示す。""",
        5: """current surfaceは12 shared skills、43 user commands、57 focused suites、7 Linux profiles。観測、transaction、recovery、distribution、collaborationをplan-by-defaultとexplicit live gateで扱う。surface countは品質指標ではない。

成熟を示すのは追加だけではない。automatic Git hook、website固有ownership、private Bash/tmux duplication、harness-owned native Codexを撤回した。境界を狭める判断がcontrol planeを安全にした。

次段階はhuman coordinationを減らすこと。ただしauthority、provenance、native-system transparencyを弱めない。このdeckはHPC scaling、universal agent quality、完全な事故forensics、model authorship/honesty、read confidentiality、retention deletion authority、future external stateを主張しない。""",
    }


def build_slides() -> list[bd.Slide]:
    n = notes()
    slides: list[bd.Slide] = []

    # Slide 1
    s = bd.Slide(
        "「設定を配る仕組み」から「証拠で制御する仕組み」へ",
        "7f969317 → 7c592af • timeline.csv • source-map-ja-5slides.md",
        notes=n[1],
        dark=True,
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="navy", line="navy")
    s.text(0.78, 0.58, 7.25, 1.32, "「設定を配る仕組み」から\n「証拠で制御する仕組み」へ", size=28, bold=True, color="white", min_size=24)
    s.text(0.80, 2.15, 6.85, 0.98, "権限・状態・環境差を明示し、\n短命な証拠に束縛し、実行前後で再検証する", size=16.2, color="gray2")
    s.rect(8.10, 0.68, 4.42, 2.78, fill="navy2", line="cyan", radius=0.18)
    label(s, 8.38, 0.94, 1.15, "SOURCE HEAD", "cyan")
    s.text(8.42, 1.46, 3.80, 0.55, "7日間の進化", size=24, bold=True, color="white", align="center")
    s.text(8.42, 2.20, 3.80, 0.66, "543 commits = 543 first-parent\n0 tags • 0 merge commits", size=11.6, color="gray2", align="center")
    s.text(8.42, 3.01, 3.80, 0.18, "履歴範囲であり、品質指標ではない", size=7.5, color="cyan", align="center")
    s.line(0.94, 4.10, 12.30, 4.10, color="gray2", width=1.2)
    stages = [
        ("守る", "Policy", "blue"), ("観る", "Inventory", "cyan"),
        ("動かす", "Transaction", "teal"), ("戻す", "Recovery", "amber"),
        ("測る", "Evidence", "violet"), ("広げる", "Mac/Fleet", "magenta"),
        ("協働", "Cowork", "green"),
    ]
    for i, (jp, en, c) in enumerate(stages):
        x = 0.78 + i * 1.78
        s.ellipse(x + 0.61, 3.92, 0.26, 0.26, fill=c, line=c)
        s.rect(x, 4.43, 1.48, 0.92, fill=bd.tint(c, 0.84), line=c, radius=0.13)
        s.text(x + 0.08, 4.60, 1.32, 0.24, jp, size=12.4, bold=True, color=c, align="center")
        s.text(x + 0.08, 4.98, 1.32, 0.16, en, size=7.4, color="darkgray", align="center")
    s.rect(0.78, 5.82, 11.88, 0.72, fill="navy2", line="teal", radius=0.14)
    s.text(1.06, 6.02, 11.32, 0.30, "中心命題：差を消したのではない。差を説明し、権限を限定し、結果を証拠化できるようにした。", size=11.4, bold=True, color="white", align="center")
    footer(s, 1, "7f969317 → 7c592af • README.md • bin/harness • complete linear history")
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
        "transaction loop が異種環境を統一せずに統御可能にした",
        "初期 architecture と current control plane の比較",
        notes=n[3],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "標準化したのはmachineではなく、観測・判断・実行・証拠化の文法")
    s.rect(0.62, 1.42, 3.08, 4.82, fill="white", line="blue", radius=0.16)
    label(s, 0.88, 1.69, 1.42, "14 JUL 2026", "blue")
    s.text(0.88, 2.22, 2.56, 0.34, "Portable discovery", size=17, bold=True, color="ink", align="center")
    initial = [("Repository", "blue"), ("Installer", "teal"), ("Known symlink", "cyan"), ("Client discovery", "violet")]
    for i, (t, c) in enumerate(initial):
        y = 2.92 + i * 0.68
        s.rect(1.02, y, 2.28, 0.48, fill=bd.tint(c, 0.88), line=c, radius=0.10)
        s.text(1.16, y + 0.13, 2.00, 0.18, t, size=9.4, bold=True, color=c, align="center")
        if i < 3:
            s.line(2.16, y + 0.49, 2.16, y + 0.66, color="gray2", width=1.1, arrow="end")
    s.text(0.98, 5.72, 2.36, 0.22, "inventory / comparison / verification なし", size=7.5, color="muted", align="center")
    s.rect(3.95, 1.42, 8.75, 4.82, fill="white", line="green", radius=0.16)
    label(s, 4.22, 1.69, 1.10, "HEAD", "green")
    s.text(4.25, 2.18, 8.02, 0.34, "Transactional evidence loop", size=17, bold=True, color="ink", align="center")
    sources = [("Policy / Source", "blue"), ("Profile / Fact", "cyan"), ("Manifest / Receipt", "teal")]
    for i, (t, c) in enumerate(sources):
        x = 4.30 + i * 2.08
        s.rect(x, 2.82, 1.82, 0.58, fill=bd.tint(c, 0.88), line=c, radius=0.11)
        s.text(x + 0.08, 2.99, 1.66, 0.18, t, size=8.4, bold=True, color=c, align="center")
        s.line(x + 0.91, 3.42, 7.30, 3.77, color="gray2", width=0.8)
    s.ellipse(6.08, 3.60, 2.48, 1.02, fill="navy", line="navy")
    s.text(6.31, 3.94, 2.02, 0.20, "OBSERVE • PLAN • APPLY • VERIFY", size=8.4, bold=True, color="white", align="center")
    outputs = [("Linux / HPC", "violet"), ("Mac + private", "magenta"), ("Backup / Fleet", "amber"), ("Clients / Cowork", "green")]
    for i, (t, c) in enumerate(outputs):
        x = 4.20 + i * 2.04
        s.rect(x, 5.00, 1.78, 0.56, fill=bd.tint(c, 0.88), line=c, radius=0.11)
        s.text(x + 0.08, 5.16, 1.62, 0.18, t, size=8.2, bold=True, color=c, align="center")
        s.line(7.31, 4.64, x + 0.89, 4.98, color="gray2", width=0.8, arrow="end")
    s.rect(4.22, 5.78, 8.12, 0.27, fill="gray", line="gray2", radius=0.08, dash=True)
    s.text(4.40, 5.85, 7.76, 0.14, "外側：credentials • site substrate • project runtimes • private intent", size=7.4, color="muted", align="center")
    stage_text = [("守", "blue"), ("観", "cyan"), ("動", "teal"), ("復", "amber"), ("測", "violet"), ("拡", "magenta"), ("協", "green")]
    for i, (t, c) in enumerate(stage_text):
        x = 1.26 + i * 1.62
        s.ellipse(x, 6.48, 0.34, 0.34, fill=c, line=c)
        s.text(x + 0.02, 6.57, 0.30, 0.13, t, size=7.2, bold=True, color="white", align="center")
        if i < 6:
            s.line(x + 0.35, 6.65, x + 1.56, 6.65, color="gray2", width=0.8)
    footer(s, 3, "7f969317 • fb417282 • 07351a40 • docs/environment-portability.md • current dispatcher")
    slides.append(s)

    # Slide 4
    s = bd.Slide(
        "評価・readiness・restore が「改善」を測定可能な主張に限定した",
        "数値には必ずscopeを付ける：readiness ≠ performance、corpus ≠ universal quality",
        notes=n[4],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "checked-in evidence のscoreboard — 一般化できない範囲も同時に表示")
    metric(s, 0.62, 1.48, 2.25, 1.48, "7 / 7", "CPU readiness", "7 Linux nodes", "cyan")
    metric(s, 3.02, 1.48, 2.25, 1.48, "7 / 7", "accelerator driver/runtime", "readiness only", "teal")
    metric(s, 5.42, 1.48, 2.25, 1.48, "5", "CUDA kernel pass", "2 toolkit skips", "violet")
    metric(s, 7.82, 1.48, 2.25, 1.48, "5", "single-node MPI routes", "2 no-route nodes", "amber")
    metric(s, 10.22, 1.48, 2.25, 1.48, "4 / 4", "personal Mac accepted", "snapshot: 7c592af", "magenta")
    s.rect(0.62, 3.24, 4.05, 2.02, fill=bd.tint("violet", 0.94), line="violet", radius=0.15)
    label(s, 0.88, 3.49, 1.20, "T-181", "violet")
    s.text(0.92, 3.92, 1.66, 0.54, "69 / 70", size=25, bold=True, color="violet", align="center")
    s.text(2.56, 3.90, 1.75, 0.46, "deterministic pass\n0 safety failures", size=10.3, bold=True, color="ink", align="center")
    s.text(0.92, 4.72, 3.40, 0.20, "targeted review 70/70 は別尺度 • candidate不採用", size=7.4, color="muted", align="center")
    s.rect(4.88, 3.24, 3.20, 2.02, fill=bd.tint("green", 0.94), line="green", radius=0.15)
    label(s, 5.14, 3.49, 1.26, "RECOVERY", "green")
    s.text(5.24, 3.94, 2.48, 0.46, "7 + 7", size=25, bold=True, color="green", align="center")
    s.text(5.24, 4.54, 2.48, 0.40, "primary + independent generation\nfull check / verified restore", size=8.6, color="ink", align="center")
    s.rect(8.30, 3.24, 4.18, 2.02, fill="white", line="blue", radius=0.15)
    label(s, 8.56, 3.49, 1.50, "HOST-SPECIFIC", "blue")
    s.text(8.62, 3.96, 1.02, 0.30, "29.69s", size=13.2, bold=True, color="muted", align="right")
    s.rect(9.78, 4.02, 2.12, 0.20, fill="gray2", line="gray2", radius=0.06)
    s.text(8.62, 4.48, 1.02, 0.30, "25.35s", size=13.2, bold=True, color="blue", align="right")
    s.rect(9.78, 4.54, 1.81, 0.20, fill="blue", line="blue", radius=0.06)
    s.text(11.60, 4.42, 0.70, 0.34, "−14.62%", size=8.2, bold=True, color="blue", align="center")
    s.text(8.62, 4.96, 3.54, 0.16, "cowork focused suite • one 8-CPU-visible host", size=7.1, color="muted", align="center")
    s.rect(0.62, 5.62, 11.86, 0.96, fill="navy", line="navy", radius=0.14)
    claims = [("支持", "readiness", "cyan"), ("支持", "corpus score", "violet"), ("支持", "restore", "green"), ("未主張", "performance / scaling", "red"), ("未主張", "universal agent quality", "red")]
    for i, (tag, text_value, c) in enumerate(claims):
        x = 0.88 + i * 2.30
        s.text(x, 5.83, 0.62, 0.18, tag, size=7.5, bold=True, color=c, align="center")
        s.text(x + 0.64, 5.83, 1.38, 0.18, text_value, size=7.7, color="white", align="left")
    s.text(0.96, 6.24, 11.18, 0.16, "改善の意味は「数字が大きい」ではなく、主張・scope・反証条件を追跡できること。", size=8.3, bold=True, color="white", align="center")
    footer(s, 4, "HPC audit JSON • T-181 results/review • backup acceptance • T-284 matched samples • 7c592af:TODO.md")
    slides.append(s)

    # Slide 5
    s = bd.Slide(
        "現在の広さより、境界を縮め続ける能力が次の成熟を決める",
        "current surface、重要なreversal、次段階、evidence limits",
        notes=n[5],
    )
    s.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(s, "機能追加だけでなく、誤ったownershipを撤回できるcontrol plane")
    s.rect(0.62, 1.42, 3.08, 4.92, fill="white", line="teal", radius=0.15)
    label(s, 0.88, 1.68, 1.42, "CURRENT GRAMMAR", "teal")
    grammar = [("OBSERVE", "inventory • status • doctor"), ("PLAN", "diff • preflight • explicit scope"), ("APPLY", "transaction • live gate"), ("VERIFY", "receipt • rollback • acceptance")]
    for i, (head, body) in enumerate(grammar):
        y = 2.22 + i * 0.78
        s.rect(0.94, y, 2.42, 0.57, fill=bd.tint("teal", 0.91), line="teal", radius=0.10)
        s.text(1.06, y + 0.10, 0.78, 0.18, head, size=8.6, bold=True, color="teal")
        s.text(1.84, y + 0.10, 1.40, 0.28, body, size=7.0, color="muted")
        if i < 3:
            s.line(2.15, y + 0.58, 2.15, y + 0.76, color="gray2", width=1.0, arrow="end")
    s.text(0.96, 5.54, 2.38, 0.32, "12 skills • 43 commands\n57 suites • 7 Linux profiles", size=10.2, bold=True, color="ink", align="center")
    s.text(0.96, 6.02, 2.38, 0.16, "breadth ≠ quality", size=7.4, color="muted", align="center")
    s.rect(3.95, 1.42, 4.84, 4.92, fill="white", line="violet", radius=0.15)
    label(s, 4.21, 1.68, 1.40, "REVERSALS", "violet")
    reversals = [
        ("login fetch / exit publish", "explicit Git operations", "e52a3d0"),
        ("website ownership", "repository independence", "f1b095c"),
        ("private Bash / tmux", "public engine + private SSH", "4209ee8"),
        ("harness-owned Codex", "local native client + wrapper", "d76575c"),
    ]
    for i, (before, after, sha) in enumerate(reversals):
        y = 2.20 + i * 0.83
        s.text(4.22, y, 1.74, 0.29, before, size=7.7, bold=True, color="red", align="right")
        s.line(6.08, y + 0.15, 6.48, y + 0.15, color="gray2", width=1.1, arrow="end")
        s.text(6.62, y, 1.56, 0.29, after, size=7.7, bold=True, color="green")
        s.text(8.20, y + 0.04, 0.48, 0.14, sha, size=5.5, color="muted", align="right")
    s.rect(4.26, 5.72, 4.20, 0.40, fill=bd.tint("violet", 0.92), line="violet", radius=0.10)
    s.text(4.46, 5.83, 3.80, 0.16, "成熟 = 追加 + 縮小 + 拒否", size=9.4, bold=True, color="violet", align="center")
    s.rect(9.04, 1.42, 3.66, 4.92, fill="white", line="amber", radius=0.15)
    label(s, 9.30, 1.68, 1.40, "NEXT / LIMITS", "amber")
    s.text(9.35, 2.22, 3.02, 0.46, "次段階", size=11.4, bold=True, color="ink", align="center")
    s.text(9.35, 2.78, 3.02, 0.62, "human coordinationを減らす\nauthority / provenance / native transparencyは維持", size=8.8, color="ink", align="center")
    s.line(9.42, 3.60, 12.30, 3.60, color="line", width=1.0)
    s.text(9.35, 3.82, 3.02, 0.30, "このdeckが主張しないこと", size=10.0, bold=True, color="red", align="center")
    limits = "HPC performance / scaling\nuniversal agent quality\n完全な事故forensics\nmodel authorship / honesty\nread confidentiality\nretention deletion authority\nfuture external state"
    s.text(9.52, 4.30, 2.68, 1.40, limits, size=8.0, color="muted", align="center")
    s.rect(0.62, 6.53, 12.08, 0.37, fill="navy", line="navy", radius=0.10)
    s.text(0.88, 6.63, 11.56, 0.16, "結論：強い自律性は、広い権限ではなく、狭く説明可能で再検証される権限から生まれる。", size=9.2, bold=True, color="white", align="center")
    footer(s, 5, "7c592af current surface • reversal commits • source-map-ja-5slides.md • evidence limitations")
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
