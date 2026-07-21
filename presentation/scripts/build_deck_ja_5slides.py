#!/usr/bin/env python3
"""Build and render the single-slide Japanese harness-evolution summary."""

from __future__ import annotations

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
    slide.text(
        0.68,
        0.35,
        12.0,
        0.64,
        slide.title,
        size=25.5,
        bold=True,
        color="ink",
        min_size=21,
    )
    slide.text(0.70, 1.00, 11.9, 0.30, subtitle, size=10.8, color="muted")


def footer(slide: bd.Slide, source: str) -> None:
    slide.line(0.68, 7.08, 12.66, 7.08, color="line", width=0.8)
    slide.text(
        0.70,
        7.12,
        11.45,
        0.18,
        source,
        size=6.6,
        color="muted",
        min_size=6.0,
    )
    slide.text(12.25, 7.10, 0.36, 0.20, "1", size=7.5, bold=True, color="muted", align="right")


def label(slide: bd.Slide, x: float, y: float, w: float, text: str, color: str) -> None:
    slide.rect(x, y, w, 0.30, fill=bd.tint(color, 0.83), line=color, radius=0.11)
    slide.text(
        x + 0.06,
        y + 0.07,
        w - 0.12,
        0.15,
        text,
        size=8.2,
        bold=True,
        color=color,
        align="center",
    )


def speaker_notes() -> str:
    return """complete historyは544 total / 544 first-parent commits、tag 0、merge commit 0。意味のある変化はProtect、Observe、Transact、Recover、Measure、Expand、Collaborateの7段階に圧縮できる。current surfaceは12 skills、43 commands、57 focused suites、7 Linux profilesだが、countは品質指標ではない。

checked-in evidenceはCPU readiness 7/7、accelerator driver/runtime 7/7、CUDA kernel 5、single-node MPI routes 5、T-181 deterministic 69/70かつsafety failure 0、backup/restore 7 primary + 7 independent generation、cowork matched median 29.69s→25.35sを示す。readinessはperformanceではなく、corpus/host-specific limitsを伴う。

成熟を示すのは追加だけではない。automatic login Git、website ownership、private Bash/tmux duplication、harness-owned native Codexを撤回した。次段階はhuman coordinationを減らすことだが、authority、provenance、native transparencyを維持する。このslideはHPC scaling、universal agent quality、完全な事故forensics、authorship/honesty、read confidentiality、retention deletion authority、future external stateを主張しない。"""


def build_slides() -> list[bd.Slide]:
    slide = bd.Slide(
        "残りの進化史は「測定・回復・撤回」で現在の境界に収束した",
        "7 stages • checked-in evidence • reversals • current surface • limits",
        notes=speaker_notes(),
    )
    slide.rect(0, 0, bd.W_IN, bd.H_IN, fill="light", line="light")
    title(slide, "追加した機能より、何を証明し、何を戻し、何を所有しないか")

    slide.line(0.72, 1.86, 12.56, 1.86, color="gray2", width=1.0)
    stage_data = [
        ("守る", "Policy", "blue"),
        ("観る", "Observe", "cyan"),
        ("動かす", "Transact", "teal"),
        ("戻す", "Recover", "amber"),
        ("測る", "Measure", "violet"),
        ("広げる", "Expand", "magenta"),
        ("協働", "Cowork", "green"),
    ]
    for i, (jp, en, color) in enumerate(stage_data):
        x = 0.58 + i * 1.70
        slide.ellipse(x + 0.58, 1.72, 0.26, 0.26, fill=color, line=color)
        slide.rect(x, 2.08, 1.42, 0.62, fill=bd.tint(color, 0.88), line=color, radius=0.10)
        slide.text(x + 0.07, 2.21, 1.28, 0.18, jp, size=9.2, bold=True, color=color, align="center")
        slide.text(x + 0.07, 2.46, 1.28, 0.12, en, size=6.2, color="muted", align="center")
    slide.text(10.62, 1.42, 1.92, 0.18, "544 / 544 first-parent", size=7.1, bold=True, color="ink", align="right")
    slide.text(10.62, 1.62, 1.92, 0.14, "0 tags • 0 merges", size=6.4, color="muted", align="right")

    slide.rect(0.55, 2.98, 4.12, 3.46, fill="white", line="teal", radius=0.15)
    label(slide, 0.80, 3.20, 1.46, "EVIDENCE", "teal")
    evidence = [
        ("7/7", "CPU", "cyan"),
        ("7/7", "Accel drv/runtime", "teal"),
        ("5", "CUDA kernel", "violet"),
        ("5", "MPI routes", "amber"),
        ("69/70", "T-181 deterministic", "violet"),
        ("0", "safety failures", "green"),
        ("7+7", "verified restore", "green"),
        ("−14.62%", "cowork median", "blue"),
    ]
    for i, (value, caption, color) in enumerate(evidence):
        x = 0.80 + (i % 2) * 1.86
        y = 3.72 + (i // 2) * 0.61
        slide.rect(x, y, 1.68, 0.48, fill=bd.tint(color, 0.92), line=color, radius=0.08)
        slide.text(x + 0.07, y + 0.10, 0.58, 0.18, value, size=8.4, bold=True, color=color, align="center")
        slide.text(x + 0.66, y + 0.10, 0.94, 0.20, caption, size=6.4, color="muted", align="center")
    slide.text(0.82, 6.20, 3.58, 0.14, "readiness / corpus / host-specific — not universal performance", size=6.3, color="muted", align="center")

    slide.rect(4.88, 2.98, 4.04, 3.46, fill="white", line="violet", radius=0.15)
    label(slide, 5.14, 3.20, 1.34, "REVERSALS", "violet")
    reversals = [
        ("login fetch / exit publish", "explicit Git operations", "e52a3d0"),
        ("website ownership", "repository independence", "f1b095c"),
        ("private Bash / tmux", "public engine + private SSH", "4209ee8"),
        ("harness-owned Codex", "local native client + wrapper", "d76575c"),
    ]
    for i, (before, after, sha) in enumerate(reversals):
        y = 3.76 + i * 0.55
        slide.text(5.12, y, 1.24, 0.22, before, size=6.6, bold=True, color="red", align="right")
        slide.line(6.45, y + 0.11, 6.72, y + 0.11, color="gray2", width=0.9, arrow="end")
        slide.text(6.82, y, 1.48, 0.22, after, size=6.6, bold=True, color="green")
        slide.text(8.32, y + 0.03, 0.38, 0.12, sha, size=4.9, color="muted", align="right")
    slide.rect(5.18, 6.02, 3.44, 0.26, fill=bd.tint("violet", 0.92), line="violet", radius=0.07)
    slide.text(5.36, 6.09, 3.08, 0.12, "成熟 = 追加 + 回復 + 縮小 + 拒否", size=7.4, bold=True, color="violet", align="center")

    slide.rect(9.13, 2.98, 3.65, 3.46, fill="white", line="amber", radius=0.15)
    label(slide, 9.39, 3.20, 1.46, "CURRENT / LIMITS", "amber")
    counts = [
        ("12", "skills", "violet"),
        ("43", "commands", "teal"),
        ("57", "suites", "green"),
        ("7", "Linux profiles", "cyan"),
    ]
    for i, (value, caption, color) in enumerate(counts):
        x = 9.42 + (i % 2) * 1.50
        y = 3.70 + (i // 2) * 0.66
        slide.rect(x, y, 1.30, 0.52, fill=bd.tint(color, 0.92), line=color, radius=0.09)
        slide.text(x + 0.08, y + 0.10, 0.42, 0.20, value, size=9.8, bold=True, color=color, align="center")
        slide.text(x + 0.52, y + 0.12, 0.70, 0.16, caption, size=6.4, color="muted", align="center")
    slide.text(9.44, 5.02, 3.02, 0.34, "NEXT: coordination ↓\nauthority / provenance / native transparency = keep", size=6.2, bold=True, color="ink", align="center")
    slide.line(9.48, 5.44, 12.44, 5.44, color="line", width=0.9)
    slide.text(9.44, 5.62, 3.02, 0.16, "NOT CLAIMED", size=7.2, bold=True, color="red", align="center")
    slide.text(9.48, 5.88, 2.94, 0.32, "HPC scaling • universal quality • full forensics\nauthorship/honesty • confidentiality • future state", size=6.2, color="muted", align="center")

    slide.rect(0.55, 6.60, 12.23, 0.28, fill="navy", line="navy", radius=0.08)
    slide.text(0.82, 6.67, 11.69, 0.13, "結論：強い自律性は、広い権限ではなく、狭く説明可能で再検証される権限から生まれる。", size=7.8, bold=True, color="white", align="center")
    footer(slide, "timeline.csv • metrics.csv • audit/evaluation results • reversal commits • 90451d4:TODO.md • evidence limits")
    return [slide]


def contact_sheet() -> None:
    image = Image.open(RENDER_DIR / "slide-01.png").convert("RGB")
    image.thumbnail((576, 324), Image.Resampling.LANCZOS)
    sheet = Image.new("RGB", (596, 354), (235, 239, 246))
    sheet.paste(image, (10, 10))
    draw = ImageDraw.Draw(sheet)
    draw.text((10, 337), "Slide 1", font=bd.font(8, bold=True), fill=bd.rgb("muted"))
    sheet.save(CONTACT)


def main() -> int:
    slides = build_slides()
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    warnings = [
        f"slide 1: {warning}"
        for warning in bd.render_slide(slides[0], RENDER_DIR / "slide-01.png")
    ]
    bd.build_pptx(slides)
    contact_sheet()
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
