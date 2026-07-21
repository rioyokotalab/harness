#!/usr/bin/env python3
"""Build and render the editable harness-evolution PowerPoint.

The environment has no installed slides skill, PowerPoint library, or office
renderer. This script therefore writes a small standards-based OOXML package
directly and renders the same scene graph with Pillow for visual inspection.
All diagrams, timelines, bars, labels, and connectors are native PowerPoint
shapes; only the decorative cover is raster artwork.
"""

from __future__ import annotations

import argparse
import html
import math
import re
import shutil
import textwrap
import zipfile
from dataclasses import dataclass, field
from pathlib import Path, PurePosixPath
from typing import Any
from xml.etree import ElementTree as ET

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "presentation/output"
ASSET = OUT / "assets/cover-control-network.png"
PPTX = OUT / "harness-evolution.pptx"
RENDER_DIR = OUT / "rendered"

W_IN, H_IN = 13.333333, 7.5
EMU = 914400
PX_PER_IN = 144
W_PX, H_PX = round(W_IN * PX_PER_IN), round(H_IN * PX_PER_IN)

FONT_REG = "/usr/share/fonts/opentype/urw-base35/NimbusSans-Regular.otf"
FONT_BOLD = "/usr/share/fonts/opentype/urw-base35/NimbusSans-Bold.otf"
FONT_ITALIC = "/usr/share/fonts/opentype/urw-base35/NimbusSans-Italic.otf"
PPT_FONT = "Arial"

COLORS = {
    "navy": "08152F",
    "navy2": "102446",
    "ink": "14213D",
    "muted": "56647A",
    "light": "F6F8FC",
    "white": "FFFFFF",
    "line": "D7DFEA",
    "blue": "3B82F6",
    "cyan": "06B6D4",
    "teal": "0D9488",
    "amber": "F59E0B",
    "violet": "7C3AED",
    "magenta": "DB2777",
    "green": "16A34A",
    "red": "DC2626",
    "gray": "E8EDF4",
    "gray2": "C5CFDC",
    "darkgray": "334155",
}

STAGES = [
    ("Protect", "14 Jul", "blue"),
    ("Observe", "14 Jul", "cyan"),
    ("Transact", "14–15", "teal"),
    ("Recover", "15–17", "amber"),
    ("Measure", "16–17", "violet"),
    ("Expand", "18–20", "magenta"),
    ("Collaborate", "21 Jul", "green"),
]


def esc(value: str) -> str:
    return html.escape(value, quote=True)


def emu(v: float) -> int:
    return round(v * EMU)


def rgb(c: str) -> tuple[int, int, int]:
    c = COLORS.get(c, c).lstrip("#")
    return tuple(int(c[i : i + 2], 16) for i in (0, 2, 4))


def tint(c: str, amount: float = 0.86) -> str:
    r, g, b = rgb(c)
    vals = [round(v + (255 - v) * amount) for v in (r, g, b)]
    return "".join(f"{v:02X}" for v in vals)


def font(size_pt: float, bold: bool = False, italic: bool = False) -> ImageFont.FreeTypeFont:
    path = FONT_BOLD if bold else FONT_ITALIC if italic else FONT_REG
    return ImageFont.truetype(path, max(6, round(size_pt * PX_PER_IN / 72)))


@dataclass
class Element:
    kind: str
    x: float
    y: float
    w: float
    h: float
    props: dict[str, Any] = field(default_factory=dict)


@dataclass
class Slide:
    title: str
    footer: str
    dark: bool = False
    notes: str = ""
    elements: list[Element] = field(default_factory=list)

    def add(self, kind: str, x: float, y: float, w: float, h: float, **props: Any) -> Element:
        elem = Element(kind, x, y, w, h, props)
        self.elements.append(elem)
        return elem

    def rect(self, x: float, y: float, w: float, h: float, **props: Any) -> Element:
        return self.add("rect", x, y, w, h, **props)

    def ellipse(self, x: float, y: float, w: float, h: float, **props: Any) -> Element:
        return self.add("ellipse", x, y, w, h, **props)

    def line(self, x1: float, y1: float, x2: float, y2: float, **props: Any) -> Element:
        return self.add("line", x1, y1, x2 - x1, y2 - y1, **props)

    def text(self, x: float, y: float, w: float, h: float, text: str, **props: Any) -> Element:
        return self.add("text", x, y, w, h, text=text, **props)

    def image(self, x: float, y: float, w: float, h: float, path: Path, **props: Any) -> Element:
        return self.add("image", x, y, w, h, path=str(path), **props)


def load_notes() -> dict[int, str]:
    text = (OUT / "speaker-notes.md").read_text(encoding="utf-8")
    matches = list(re.finditer(r"^## Slide (\d+) — .+$", text, flags=re.M))
    notes: dict[int, str] = {}
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        notes[int(match.group(1))] = text[match.end() : end].strip()
    return notes


def add_title(slide: Slide, subtitle: str | None = None) -> None:
    color = "white" if slide.dark else "ink"
    slide.text(0.68, 0.38, 11.95, 0.62, slide.title, size=27, bold=True, color=color, min_size=22)
    if subtitle:
        slide.text(0.7, 1.02, 11.9, 0.34, subtitle, size=12.5, color="gray2" if slide.dark else "muted")


def add_footer(slide: Slide, number: int) -> None:
    color = "gray2" if slide.dark else "muted"
    line = "2B3B59" if slide.dark else "D7DFEA"
    slide.line(0.68, 7.08, 12.66, 7.08, color=line, width=0.8)
    slide.text(0.7, 7.12, 11.45, 0.22, slide.footer, size=7.2, color=color, min_size=6.5)
    slide.text(12.25, 7.10, 0.36, 0.22, str(number), size=8, bold=True, color=color, align="right")


def pill(slide: Slide, x: float, y: float, w: float, text: str, color: str, *, dark: bool = False) -> None:
    fill = COLORS[color] if dark else tint(color, 0.82)
    text_color = "white" if dark else color
    slide.rect(x, y, w, 0.34, fill=fill, line=color, radius=0.17, line_width=0.8)
    slide.text(x + 0.08, y + 0.055, w - 0.16, 0.21, text, size=9.2, bold=True, color=text_color, align="center")


def card(slide: Slide, x: float, y: float, w: float, h: float, *, fill: str = "white", line: str = "line", radius: float = 0.14) -> None:
    slide.rect(x, y, w, h, fill=fill, line=line, radius=radius, line_width=1.0)


def label_block(slide: Slide, x: float, y: float, w: float, h: float, title: str, body: str, color: str) -> None:
    card(slide, x, y, w, h, fill="white", line=tint(color, 0.45))
    slide.rect(x, y, 0.09, h, fill=color, line=color, radius=0.04)
    slide.text(x + 0.22, y + 0.18, w - 0.36, 0.36, title, size=16, bold=True, color="ink", min_size=13)
    slide.text(x + 0.22, y + 0.66, w - 0.36, h - 0.8, body, size=11.5, color="muted", min_size=9.2)


def build_slides() -> list[Slide]:
    notes = load_notes()
    slides: list[Slide] = []

    # 1
    s = Slide(
        "The harness became a control plane by making authority explicit",
        "Git: 7f969317 → f254295  •  Full references: sources.md",
        dark=True,
        notes=notes[1],
    )
    s.rect(0, 0, W_IN, H_IN, fill="navy", line="navy")
    s.image(0, 0, W_IN, H_IN, ASSET, crop="cover")
    s.rect(0, 0, 7.3, H_IN, fill="08152F", line="08152F", alpha=22)
    s.text(0.82, 1.18, 6.9, 1.45, s.title, size=34, bold=True, color="white", min_size=29)
    s.text(
        0.86,
        3.02,
        5.75,
        1.08,
        "From portable agent discovery to a transactional, evidence-driven control plane",
        size=18,
        color="D8E5F7",
        min_size=15,
    )
    pill(s, 0.86, 4.48, 1.12, "PROTECT", "blue", dark=True)
    pill(s, 2.10, 4.48, 1.10, "OBSERVE", "cyan", dark=True)
    pill(s, 3.32, 4.48, 1.16, "TRANSACT", "teal", dark=True)
    pill(s, 4.60, 4.48, 1.24, "EVIDENCE", "violet", dark=True)
    s.text(0.88, 5.18, 5.6, 0.5, "Repository history: 14–21 July 2026", size=11.5, color="9FB4CE")
    slides.append(s)

    # 2
    s = Slide(
        "The first harness protected portable intent—not machine state",
        "7f969317: README.md, install.sh, AGENTS.md  •  805db485: dual-client discovery",
        notes=notes[2],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Root implementation: 18 tracked files • 6 reusable skills • known symlinks only")
    card(s, 0.72, 1.52, 6.25, 4.95, fill="navy", line="navy")
    pill(s, 1.04, 1.83, 1.32, "VERSIONED", "blue", dark=True)
    s.text(1.02, 2.32, 5.55, 0.54, "Portable, non-sensitive intent", size=22, bold=True, color="white")
    blocks = [
        ("Working agreements", "Shared behavior and authority"),
        ("Command rules", "Reviewed command boundaries"),
        ("Reusable skills", "Six focused workflows"),
        ("Fail-closed installer", "Refuse collisions; create known links"),
    ]
    for i, (t, b) in enumerate(blocks):
        x = 1.02 + (i % 2) * 2.82
        y = 3.12 + (i // 2) * 1.26
        s.rect(x, y, 2.55, 0.98, fill="102446", line="3A5279", radius=0.12)
        s.text(x + 0.16, y + 0.13, 2.22, 0.25, t, size=12.5, bold=True, color="white")
        s.text(x + 0.16, y + 0.47, 2.22, 0.31, b, size=9.5, color="B8C8DE")
    s.line(7.18, 2.48, 8.08, 2.48, color="blue", width=2.2, arrow="end")
    s.rect(8.16, 1.75, 1.85, 1.4, fill=tint("blue", 0.84), line="blue", radius=0.16)
    s.text(8.38, 2.07, 1.42, 0.32, "Codex", size=18, bold=True, color="blue", align="center")
    s.text(8.38, 2.48, 1.42, 0.24, "discovery", size=10.5, color="muted", align="center")
    s.rect(10.2, 1.75, 1.85, 1.4, fill=tint("cyan", 0.86), line="cyan", radius=0.16)
    s.text(10.42, 2.07, 1.42, 0.32, "Claude", size=18, bold=True, color="cyan", align="center")
    s.text(10.42, 2.48, 1.42, 0.24, "+1 commit", size=10.5, color="muted", align="center")
    card(s, 7.55, 3.62, 5.03, 2.85, fill="gray", line="gray2")
    pill(s, 7.86, 3.9, 1.46, "EXCLUDED", "darkgray")
    s.text(7.88, 4.43, 4.32, 0.45, "Private / high-churn runtime state", size=17, bold=True, color="darkgray")
    s.text(
        7.88,
        5.03,
        4.25,
        1.02,
        "Credentials  •  sessions  •  histories\nLive configuration  •  caches  •  plugins",
        size=12,
        color="muted",
        min_size=10,
    )
    add_footer(s, 2)
    slides.append(s)

    # 3
    s = Slide(
        "Seven architectural shifts turned discovery into controlled execution",
        "timeline.csv • milestones.md • git log --first-parent --reverse",
        notes=notes[3],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "Complete linear history: 542 total = 542 first-parent commits • 0 tags • 0 merge commits")
    x0, y0, gap = 0.72, 2.35, 0.13
    stage_w = (11.92 - gap * 6) / 7
    s.line(0.86, 3.68, 12.45, 3.68, color="gray2", width=2.0)
    anchors = ["7f969317", "fb417282", "07351a40", "238f022", "05932762", "a0b74a4", "535a492"]
    for i, ((name, date, color), sha) in enumerate(zip(STAGES, anchors)):
        x = x0 + i * (stage_w + gap)
        s.rect(x, y0, stage_w, 1.12, fill=tint(color, 0.84), line=color, radius=0.12)
        s.text(x + 0.12, y0 + 0.18, stage_w - 0.24, 0.32, name, size=14.5, bold=True, color=color, align="center")
        s.text(x + 0.12, y0 + 0.60, stage_w - 0.24, 0.22, date, size=9.5, color="muted", align="center")
        cx = x + stage_w / 2
        s.ellipse(cx - 0.085, 3.595, 0.17, 0.17, fill=color, line=color)
        s.text(x, 4.03, stage_w, 0.22, sha, size=7.8, color="muted", align="center")
    s.text(0.76, 4.68, 2.2, 0.25, "Recorded reversals", size=11, bold=True, color="red")
    reversals = [
        (5.35, "Remove automatic\nGit hooks", "e52a3d0"),
        (7.32, "Remove website\nownership", "f1b095c"),
        (9.30, "Return native client\nownership", "d76575c"),
    ]
    for x, label, sha in reversals:
        s.line(x, 4.55, x, 5.03, color="red", width=1.4, arrow="end")
        s.rect(x - 0.63, 5.08, 1.26, 0.88, fill=tint("red", 0.9), line="red", radius=0.10)
        s.text(x - 0.55, 5.18, 1.10, 0.40, label, size=8.6, bold=True, color="red", align="center", min_size=7.6)
        s.text(x - 0.55, 5.63, 1.10, 0.18, sha, size=7.2, color="muted", align="center")
    pill(s, 10.85, 1.50, 1.62, "INTERPRETATION", "violet")
    s.text(8.05, 1.48, 2.58, 0.4, "Stages reflect consequences,\nnot change volume", size=10.3, color="muted", align="right")
    add_footer(s, 3)
    slides.append(s)

    # 4
    s = Slide(
        "Versioned links were a foundation, not yet an operating system",
        "7f969317 • 805db485 • milestone diff to fb417282",
        notes=notes[4],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Initial architecture: portable discovery with a deliberately narrow ownership boundary")
    nodes = [
        (0.82, 2.05, 2.20, "Git repository", "policy • rules • skills", "blue"),
        (3.55, 2.05, 2.20, "Installer", "preflight every link", "teal"),
        (6.28, 2.05, 2.20, "Known symlinks", "create or refuse", "cyan"),
        (9.01, 2.05, 3.10, "Client discovery", "Codex + Claude", "violet"),
    ]
    for x, y, w, t, b, c in nodes:
        s.rect(x, y, w, 1.35, fill="white", line=c, radius=0.16, line_width=1.5)
        s.text(x + 0.14, y + 0.26, w - 0.28, 0.33, t, size=16, bold=True, color=c, align="center")
        s.text(x + 0.14, y + 0.78, w - 0.28, 0.24, b, size=10.5, color="muted", align="center")
    for x in [3.10, 5.83, 8.56]:
        s.line(x, 2.72, x + 0.36, 2.72, color="darkgray", width=1.8, arrow="end")
    s.rect(0.82, 3.79, 11.29, 0.62, fill="gray", line="gray2", radius=0.10, dash=True)
    s.text(1.10, 3.96, 10.72, 0.22, "Outside ownership: credentials • runtime state • live configuration • site substrate", size=11.2, color="muted", align="center")
    s.text(0.82, 4.82, 2.2, 0.30, "What it could not do", size=15, bold=True, color="ink")
    missing = [
        ("No inventory", "machine unknown"),
        ("No comparison", "desired state unknown"),
        ("No mutation", "manual coordination"),
        ("No verification", "health unproven"),
    ]
    for i, (t, b) in enumerate(missing):
        x = 0.82 + i * 3.02
        s.rect(x, 5.31, 2.72, 1.00, fill="white", line="gray2", radius=0.12, dash=True)
        s.text(x + 0.15, 5.49, 2.42, 0.26, t, size=13.2, bold=True, color="darkgray", align="center")
        s.text(x + 0.15, 5.87, 2.42, 0.21, b, size=9.5, color="muted", align="center")
    add_footer(s, 4)
    slides.append(s)

    # 5
    s = Slide(
        "Value-free observation made heterogeneity actionable",
        "fb417282 • docs/environment-portability.md • profiles/hosts/ • tests/fixtures/",
        notes=notes[5],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "The harness standardized a control grammar—not the machines")
    hosts = [("local", "ybatch"), ("ab", "PBS"), ("ri", "Slurm"), ("al", "uenv"), ("t4", "AGE")]
    for i, (h, sched) in enumerate(hosts):
        y = 1.72 + i * 0.82
        c = ["blue", "cyan", "teal", "amber", "violet"][i]
        s.rect(0.75, y, 1.65, 0.56, fill=tint(c, 0.86), line=c, radius=0.14)
        s.text(0.91, y + 0.10, 0.55, 0.22, h, size=11.5, bold=True, color=c)
        s.text(1.46, y + 0.10, 0.74, 0.22, sched, size=9.5, color="muted", align="right")
        s.line(2.44, y + 0.28, 3.10, 3.37, color="gray2", width=0.9)
    flow = [
        (3.18, 2.08, 2.28, 2.58, "INVENTORY", "Value-free facts", "OS / arch\ncommand presence\nlink kinds", "cyan"),
        (5.90, 2.08, 2.28, 2.58, "PLAN", "Profile comparison", "desired vs observed\ncreates / keeps / blocks", "teal"),
        (8.62, 2.08, 2.28, 2.58, "DOCTOR", "Readiness result", "failures\nwarnings\nintentional skips", "green"),
    ]
    for x, y, w, h, eyebrow, title, body, c in flow:
        card(s, x, y, w, h, fill="light", line=c)
        pill(s, x + 0.24, y + 0.24, 1.18, eyebrow, c)
        s.text(x + 0.24, y + 0.83, w - 0.48, 0.42, title, size=16, bold=True, color="ink", align="center")
        s.text(x + 0.32, y + 1.45, w - 0.64, 0.72, body, size=11, color="muted", align="center")
    s.line(5.49, 3.37, 5.80, 3.37, color="darkgray", width=1.8, arrow="end")
    s.line(8.21, 3.37, 8.52, 3.37, color="darkgray", width=1.8, arrow="end")
    card(s, 11.20, 2.08, 1.38, 2.58, fill=tint("red", 0.94), line="red")
    s.text(11.39, 2.31, 1.0, 0.42, "NEVER\nREAD", size=13, bold=True, color="red", align="center")
    s.text(11.36, 3.13, 1.05, 1.0, "credentials\nenvironment values\nstartup contents", size=9.4, color="muted", align="center")
    card(s, 3.18, 5.20, 9.40, 0.96, fill=tint("violet", 0.94), line=tint("violet", 0.65))
    s.text(3.40, 5.39, 8.96, 0.27, "Native site semantics remain visible: Slurm • PBS • AGE • modules • uenv", size=14, bold=True, color="violet", align="center")
    s.text(3.40, 5.76, 8.96, 0.18, "Profiles explain differences; they do not conceal them behind a normalized scheduler wrapper.", size=9.5, color="muted", align="center")
    add_footer(s, 5)
    slides.append(s)

    # 6
    s = Slide(
        "Transactions replaced fragile manual coordination",
        "07351a40 • 42e9a119 • 37ff256a • 238f022 • e8b0e9ae • 1ed9712",
        notes=notes[6],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "One control grammar—operation-specific contracts")
    cx, cy = 6.66, 3.85
    steps = [
        (cx - 4.65, cy - 1.73, "1", "Observe", "facts"),
        (cx - 2.45, cy - 2.40, "2", "Plan", "default"),
        (cx + 0.10, cy - 2.40, "3", "Revalidate", "live state"),
        (cx + 2.65, cy - 1.73, "4", "Apply", "owned paths"),
        (cx + 2.65, cy + 0.25, "5", "Verify", "health"),
        (cx + 0.10, cy + 0.92, "6", "Record", "manifest"),
        (cx - 2.45, cy + 0.92, "↺", "Rollback", "unchanged only"),
        (cx - 4.65, cy + 0.25, "!", "Stop", "drift / failure"),
    ]
    points = []
    for i, (x, y, num, title, sub) in enumerate(steps):
        c = ["cyan", "teal", "teal", "green", "green", "blue", "amber", "red"][i]
        s.rect(x, y, 1.80, 1.02, fill="white", line=c, radius=0.18, line_width=1.5)
        s.ellipse(x + 0.12, y + 0.16, 0.34, 0.34, fill=c, line=c)
        s.text(x + 0.12, y + 0.21, 0.34, 0.18, num, size=9.5, bold=True, color="white", align="center")
        s.text(x + 0.53, y + 0.15, 1.08, 0.26, title, size=12.4, bold=True, color="ink")
        s.text(x + 0.53, y + 0.53, 1.08, 0.20, sub, size=8.7, color="muted")
        points.append((x + 0.9, y + 0.51))
    for a, b in zip(points, points[1:] + points[:1]):
        s.line(a[0], a[1], b[0], b[1], color="gray2", width=1.1, arrow="end")
    s.ellipse(5.20, 3.06, 2.92, 1.55, fill="navy", line="navy")
    s.text(5.52, 3.34, 2.28, 0.34, "PLAN → APPLY → VERIFY", size=15.5, bold=True, color="white", align="center")
    s.text(5.54, 3.87, 2.24, 0.24, "explicit authority at every write", size=9.4, color="B8C8DE", align="center")
    domains = [("Links", "blue"), ("Tools", "teal"), ("Backups", "amber"), ("Fleet", "violet")]
    for i, (t, c) in enumerate(domains):
        pill(s, 0.82 + i * 1.42, 6.30, 1.18, t.upper(), c)
    s.text(6.68, 6.26, 5.72, 0.35, "Site software • credentials • project runtimes remain outside generic rollback", size=10.2, color="muted", align="right")
    add_footer(s, 6)
    slides.append(s)

    # 7
    s = Slide(
        "Evidence became a gate—not a post-hoc report",
        "05932762 • ee968531 • fd5c3b1 • f6b9909 • docs/audits/hpc-*-readiness-*.json",
        notes=notes[7],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "A plausible change can be rejected; a capability claim must survive its native route")
    card(s, 0.72, 1.55, 5.88, 4.92, fill=tint("violet", 0.95), line="violet")
    pill(s, 1.02, 1.84, 1.48, "AGENT EVAL", "violet")
    s.text(1.02, 2.37, 4.98, 0.45, "Candidate A entered a frozen paired experiment", size=17, bold=True, color="ink")
    s.line(1.25, 3.18, 2.13, 3.18, color="violet", width=2, arrow="end")
    s.rect(2.22, 2.75, 1.70, 0.86, fill="white", line="violet", radius=0.14)
    s.text(2.40, 2.93, 1.34, 0.24, "70 runs", size=17, bold=True, color="violet", align="center")
    s.line(4.02, 3.18, 4.90, 3.18, color="violet", width=2, arrow="end")
    s.rect(4.98, 2.64, 1.20, 1.08, fill=tint("red", 0.84), line="red", radius=0.14)
    s.text(5.10, 2.86, 0.96, 0.26, "REJECT", size=15.5, bold=True, color="red", align="center")
    s.text(1.02, 4.14, 5.02, 0.82, "No substantive gain\n+13.3% duration • +3.1% input tokens", size=15.5, bold=True, color="red", align="center")
    s.text(1.02, 5.27, 5.02, 0.55, "69/70 deterministic • 70/70 substantive review • 0 safety failures", size=10.6, color="muted", align="center")
    pill(s, 1.94, 5.93, 3.12, "CORPUS / MODEL / ENVIRONMENT SPECIFIC", "amber")
    card(s, 6.86, 1.55, 5.75, 4.92, fill=tint("cyan", 0.96), line="cyan")
    pill(s, 7.16, 1.84, 1.72, "NATIVE ROUTES", "cyan")
    s.text(7.16, 2.37, 4.90, 0.45, "Seven sites kept their real scheduler semantics", size=17, bold=True, color="ink")
    rows = [
        ("CPU", "7 pass", "0 gap", "green"),
        ("Accelerator runtime", "7 pass", "5 kernels + 2 skips", "blue"),
        ("Single-node MPI", "5 pass", "2 no route", "teal"),
        ("Multi-node MPI", "3 pass", "2 env fail + 2 excluded", "violet"),
    ]
    for i, (t, p, lim, c) in enumerate(rows):
        y = 3.10 + i * 0.67
        s.text(7.18, y, 1.90, 0.25, t, size=11.3, bold=True, color="ink")
        s.rect(9.13, y - 0.02, 1.04, 0.30, fill=tint(c, 0.83), line=c, radius=0.15)
        s.text(9.22, y + 0.04, 0.86, 0.16, p, size=8.6, bold=True, color=c, align="center")
        s.text(10.36, y, 1.88, 0.25, lim, size=9.4, color="muted")
    s.rect(7.16, 5.86, 4.92, 0.40, fill=tint("amber", 0.89), line="amber", radius=0.10)
    s.text(7.34, 5.96, 4.56, 0.18, "READINESS ≠ PERFORMANCE OR SCALING", size=9.6, bold=True, color="amber", align="center")
    add_footer(s, 7)
    slides.append(s)

    # 8
    s = Slide(
        "The public engine expanded without absorbing private Mac intent",
        "a0b74a4 • 4209ee84 • 6a7e177d • docs/personal-macos*.md • TODO.md",
        notes=notes[8],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Reusable mechanics stayed public; identity and private payload stayed owner-controlled")
    # lanes
    s.rect(0.72, 1.55, 12.0, 2.05, fill=tint("blue", 0.94), line="blue", radius=0.16)
    pill(s, 0.98, 1.80, 1.35, "PUBLIC GIT", "blue")
    public = [("Mac engine", "plan / doctor"), ("Bash hooks", "shared source"), ("tmux", "shared config"), ("Client policy", "public schema")]
    for i, (t, b) in enumerate(public):
        x = 2.60 + i * 2.35
        s.rect(x, 2.08, 2.00, 1.05, fill="white", line="blue", radius=0.12)
        s.text(x + 0.13, 2.28, 1.74, 0.25, t, size=12.5, bold=True, color="blue", align="center")
        s.text(x + 0.13, 2.67, 1.74, 0.19, b, size=9.1, color="muted", align="center")
    s.rect(0.72, 4.18, 12.0, 1.78, fill=tint("magenta", 0.95), line="magenta", radius=0.16, dash=True)
    pill(s, 0.98, 4.43, 1.72, "PRIVATE COMPANION", "magenta")
    private = [("Opaque identity", "not public"), ("Selected intent", "owner curated"), ("SSH payload", "whole-file private")]
    for i, (t, b) in enumerate(private):
        x = 3.05 + i * 2.65
        s.rect(x, 4.54, 2.25, 0.96, fill="white", line="magenta", radius=0.12, dash=True)
        s.text(x + 0.14, 4.71, 1.97, 0.24, t, size=12.2, bold=True, color="magenta", align="center")
        s.text(x + 0.14, 5.08, 1.97, 0.18, b, size=8.9, color="muted", align="center")
    # Resolver
    s.line(11.20, 3.61, 11.20, 4.14, color="teal", width=2, arrow="both")
    s.rect(10.18, 3.47, 2.04, 0.76, fill="navy", line="navy", radius=0.14)
    s.text(10.39, 3.66, 1.62, 0.24, "LOCAL RESOLVER", size=11.3, bold=True, color="white", align="center")
    s.line(2.35, 4.18, 2.35, 3.64, color="amber", width=1.8, arrow="end")
    s.text(0.99, 3.74, 1.10, 0.31, "one-way\nmigration", size=8.5, bold=True, color="amber", align="center")
    s.text(0.96, 6.27, 11.5, 0.35, "HEAD: 3 reachable Macs accepted • 1 owner-operated Mac availability-gated", size=13, bold=True, color="ink", align="center")
    add_footer(s, 8)
    slides.append(s)

    # 9
    s = Slide(
        "The control loop grew; the ownership boundary stayed narrow",
        "7f969317 vs f254295 • README.md • bin/harness • docs/environment-portability.md",
        notes=notes[9],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "Before / after architecture comparison")
    # before
    card(s, 0.65, 1.48, 4.00, 4.98, fill="light", line="blue")
    pill(s, 0.92, 1.76, 1.55, "14 JUL 2026", "blue")
    s.text(0.92, 2.30, 3.46, 0.38, "Portable discovery", size=20, bold=True, color="ink", align="center")
    for i, (t, c) in enumerate([("Repository", "blue"), ("Installer", "teal"), ("Symlinks", "cyan"), ("Clients", "violet")]):
        y = 3.02 + i * 0.72
        s.rect(1.35, y, 2.60, 0.46, fill=tint(c, 0.86), line=c, radius=0.12)
        s.text(1.55, y + 0.095, 2.20, 0.20, t, size=11.2, bold=True, color=c, align="center")
        if i < 3:
            s.line(2.65, y + 0.48, 2.65, y + 0.70, color="gray2", width=1.2, arrow="end")
    s.rect(0.94, 5.96, 3.42, 0.28, fill="gray", line="gray2", radius=0.10, dash=True)
    s.text(1.04, 6.02, 3.22, 0.14, "private state outside", size=8.5, color="muted", align="center")
    # after
    card(s, 4.98, 1.48, 7.70, 4.98, fill="light", line="green")
    pill(s, 5.25, 1.76, 1.55, "HEAD", "green")
    s.text(5.25, 2.30, 7.05, 0.38, "Transactional evidence loop", size=20, bold=True, color="ink", align="center")
    top = [("Policy + sources", "blue"), ("Profiles", "cyan"), ("Manifests", "teal")]
    for i, (t, c) in enumerate(top):
        x = 5.35 + i * 1.86
        s.rect(x, 3.00, 1.62, 0.55, fill=tint(c, 0.86), line=c, radius=0.12)
        s.text(x + 0.08, 3.13, 1.46, 0.22, t, size=9.6, bold=True, color=c, align="center")
        s.line(x + 0.81, 3.57, 8.02, 3.94, color="gray2", width=0.8)
    s.ellipse(6.77, 3.80, 2.50, 1.18, fill="navy", line="navy")
    s.text(7.05, 4.08, 1.94, 0.27, "PLAN • APPLY • VERIFY", size=12.3, bold=True, color="white", align="center")
    outputs = [("Linux/HPC", "violet"), ("Mac + private", "magenta"), ("Native clients", "green")]
    for i, (t, c) in enumerate(outputs):
        x = 5.31 + i * 1.88
        s.rect(x, 5.26, 1.68, 0.55, fill=tint(c, 0.86), line=c, radius=0.12)
        s.text(x + 0.08, 5.39, 1.52, 0.22, t, size=9.5, bold=True, color=c, align="center")
        s.line(8.02, 5.00, x + 0.84, 5.24, color="gray2", width=0.8, arrow="end")
    s.rect(11.05, 3.00, 1.24, 2.81, fill=tint("amber", 0.94), line="amber", radius=0.12)
    s.text(11.14, 3.27, 1.06, 0.32, "EVIDENCE", size=10.2, bold=True, color="amber", align="center")
    s.text(11.14, 3.88, 1.06, 0.90, "tests\naudits\nCI\nreceipts", size=9.6, color="muted", align="center")
    s.line(11.04, 4.36, 9.30, 4.36, color="amber", width=1.5, arrow="end")
    s.rect(5.26, 6.02, 7.15, 0.25, fill="gray", line="gray2", radius=0.10, dash=True)
    s.text(5.45, 6.07, 6.77, 0.13, "same outer boundary: secrets • site substrate • project runtimes", size=8.1, color="muted", align="center")
    pill(s, 0.72, 6.60, 1.62, "INTERPRETATION", "violet")
    s.text(2.54, 6.60, 9.80, 0.30, "The harness expanded what it can explain and transact—not what it is allowed to own.", size=12.3, bold=True, color="violet")
    add_footer(s, 9)
    slides.append(s)

    # 10
    s = Slide(
        "Measured outcomes improved confidence—not every number claims speed",
        "HPC/backup/evaluation JSON and audits • docs/audits/t284-cowork-acceptance.md",
        notes=notes[10],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Four evidence types answer four different questions")
    cards = [
        (0.72, 1.55, 2.88, 4.83, "FLEET", "7 / 7", "CPU readiness\nAccelerator runtime", "cyan"),
        (3.72, 1.55, 2.88, 4.83, "RECOVERY", "7 + 7", "Primaries + independent\ngenerations checked/restored", "amber"),
        (6.72, 1.55, 2.88, 4.83, "AGENT EVAL", "69 / 70", "deterministic passes\n0 safety failures", "violet"),
        (9.72, 1.55, 2.88, 4.83, "VALIDATION SPEED", "14.62%", "matched median reduction\none host", "green"),
    ]
    for x, y, w, h, tag, metric, body, c in cards:
        card(s, x, y, w, h, fill="white", line=c)
        pill(s, x + 0.25, y + 0.25, w - 0.50, tag, c)
        s.text(x + 0.22, y + 0.97, w - 0.44, 0.72, metric, size=31, bold=True, color=c, align="center")
        s.text(x + 0.28, y + 1.83, w - 0.56, 0.72, body, size=12.4, bold=True, color="ink", align="center", min_size=10)
    # categorical rings/cards
    s.ellipse(1.53, 4.24, 1.25, 1.25, fill="white", line="cyan", line_width=8)
    s.text(1.70, 4.67, 0.91, 0.26, "PASS", size=11.5, bold=True, color="cyan", align="center")
    s.ellipse(4.53, 4.24, 1.25, 1.25, fill="white", line="amber", line_width=8)
    s.text(4.69, 4.54, 0.93, 0.46, "CHECK\nRESTORE", size=9.2, bold=True, color="amber", align="center")
    s.ellipse(7.53, 4.24, 1.25, 1.25, fill="white", line="violet", line_width=8)
    s.text(7.70, 4.54, 0.91, 0.46, "FROZEN\nCORPUS", size=9.2, bold=True, color="violet", align="center")
    # bars
    s.text(10.08, 4.00, 0.68, 0.18, "jobs=4", size=8.5, color="muted")
    s.rect(10.08, 4.27, 1.90, 0.34, fill=tint("darkgray", 0.55), line="darkgray", radius=0.08)
    s.text(10.88, 4.34, 0.94, 0.14, "29.69 s", size=8, bold=True, color="darkgray", align="right")
    s.text(10.08, 4.82, 0.68, 0.18, "jobs=8", size=8.5, color="muted")
    s.rect(10.08, 5.09, 1.62, 0.34, fill="green", line="green", radius=0.08)
    s.text(10.72, 5.16, 0.82, 0.14, "25.35 s", size=8, bold=True, color="white", align="right")
    scope = [
        ("readiness ≠ performance", 0.87),
        ("restore ≠ retention automation", 3.87),
        ("corpus-specific ≠ universal", 6.87),
        ("one host ≠ fleet benchmark", 9.87),
    ]
    for txt, x in scope:
        s.rect(x, 5.82, 2.58, 0.34, fill=tint("amber", 0.90), line="amber", radius=0.10)
        s.text(x + 0.10, 5.91, 2.38, 0.15, txt.upper(), size=7.7, bold=True, color="amber", align="center")
    add_footer(s, 10)
    slides.append(s)

    # 11
    s = Slide(
        "Reversals made the harness safer than accretion alone",
        "e52a3d0 • f1b095c • fd5c3b1 • 4209ee8 • d76575c",
        notes=notes[11],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "Important lessons arrived as subtraction, rejection, and narrower ownership")
    headers = [(0.80, 2.65, "BEFORE"), (4.08, 3.65, "EVIDENCE"), (8.10, 4.43, "AFTER")]
    for x, w, t in headers:
        s.text(x, 1.53, w, 0.26, t, size=10.5, bold=True, color="muted", align="center")
    rows = [
        ("Login fetch + exit publish", "Implicit network/auth boundary", "Explicit Git operations", "e52a3d0"),
        ("Website-specific ownership", "Sibling dependency + scope leak", "Repository independence", "f1b095c"),
        ("Plausible guidance candidate", "No gain; more measured cost", "Baseline retained", "fd5c3b1"),
        ("Private Bash/tmux bundle", "Duplicated public-capable state", "Public Bash/tmux; private SSH", "4209ee8"),
        ("Harness-owned native Codex", "Runtime ownership conflict", "Local native client + wrapper", "d76575c"),
    ]
    for i, (before, evidence, after, sha) in enumerate(rows):
        y = 1.92 + i * 0.83
        fill = "F8FAFD" if i % 2 == 0 else "FFFFFF"
        s.rect(0.72, y, 11.92, 0.67, fill=fill, line="line", radius=0.08)
        s.text(0.88, y + 0.18, 2.55, 0.24, before, size=10.6, bold=True, color="darkgray")
        s.line(3.57, y + 0.34, 3.91, y + 0.34, color="red", width=1.4, arrow="end")
        s.text(4.10, y + 0.18, 3.60, 0.24, evidence, size=10.1, color="muted", align="center")
        s.line(7.77, y + 0.34, 8.03, y + 0.34, color="green", width=1.4, arrow="end")
        s.text(8.18, y + 0.18, 3.58, 0.24, after, size=10.6, bold=True, color="green")
        s.text(11.83, y + 0.19, 0.64, 0.18, sha, size=7.3, color="muted", align="right")
    s.rect(0.72, 6.26, 11.92, 0.58, fill=tint("violet", 0.93), line="violet", radius=0.12, dash=True)
    pill(s, 0.94, 6.38, 1.56, "INTERPRETATION", "violet")
    s.text(2.74, 6.39, 9.54, 0.21, "Maturity came from narrower ownership—not just more automation.", size=13, bold=True, color="violet")
    add_footer(s, 11)
    slides.append(s)

    # 12
    s = Slide(
        "HEAD is broad; the next stage is disciplined reduction of coordination",
        "f254295 • README.md • TODO.md • bin/harness • tests/focused-suites.tsv",
        notes=notes[12],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Current breadth is measurable; the next design question is qualitative")
    # capability wheel
    s.ellipse(0.92, 1.62, 4.75, 4.75, fill="white", line="line", line_width=1.2)
    center = (3.295, 3.995)
    radius = 1.66
    for i, (name, _, c) in enumerate(STAGES):
        a = -90 + i * 360 / 7
        x = center[0] + radius * math.cos(math.radians(a)) - 0.56
        y = center[1] + radius * math.sin(math.radians(a)) - 0.28
        s.rect(x, y, 1.12, 0.56, fill=tint(c, 0.83), line=c, radius=0.16)
        s.text(x + 0.08, y + 0.17, 0.96, 0.19, name, size=8.7, bold=True, color=c, align="center")
        s.line(center[0], center[1], x + 0.56, y + 0.28, color=tint(c, 0.50), width=0.8)
    s.ellipse(2.36, 3.05, 1.87, 1.87, fill="navy", line="navy")
    s.text(2.67, 3.48, 1.25, 0.36, "HEAD", size=24, bold=True, color="white", align="center")
    s.text(2.61, 3.94, 1.37, 0.35, "explicit control\nboundaries", size=9.6, color="B8C8DE", align="center")
    stats = [("12", "skills"), ("43", "commands"), ("57", "focused suites"), ("7", "Linux hosts")]
    for i, (v, lab) in enumerate(stats):
        x = 0.78 + i * 1.32
        s.text(x, 6.45, 1.06, 0.31, v, size=19, bold=True, color=["blue", "teal", "violet", "green"][i], align="center")
        s.text(x, 6.77, 1.06, 0.16, lab, size=7.7, color="muted", align="center")
    # open questions
    s.text(6.13, 1.58, 6.15, 0.36, "Three open questions", size=19, bold=True, color="ink")
    qs = [
        ("1", "Reduce coordination", "Which waits, polls, and handoffs can disappear without weakening authority?", "green"),
        ("2", "Close only demanded gaps", "Which HPC routes or backup lifecycle steps have a concrete project need?", "amber"),
        ("3", "Strengthen provenance", "How far can cowork evidence improve without claiming authorship or OS confinement?", "violet"),
    ]
    for i, (num, title, body, c) in enumerate(qs):
        y = 2.18 + i * 1.28
        s.rect(6.10, y, 6.18, 1.00, fill="white", line=c, radius=0.14, dash=True)
        s.ellipse(6.33, y + 0.23, 0.48, 0.48, fill=c, line=c)
        s.text(6.33, y + 0.33, 0.48, 0.18, num, size=10, bold=True, color="white", align="center")
        s.text(7.02, y + 0.17, 4.96, 0.25, title, size=13, bold=True, color=c)
        s.text(7.02, y + 0.51, 4.96, 0.30, body, size=9.7, color="muted", min_size=8.7)
    s.rect(6.10, 6.21, 6.18, 0.72, fill="navy", line="navy", radius=0.14)
    s.text(6.34, 6.36, 5.70, 0.36, "Next: less friction—same explicit authority, provenance, and native-system truth", size=11.4, bold=True, color="white", align="center", min_size=10)
    add_footer(s, 12)
    slides.append(s)

    # 13
    s = Slide(
        "Every claim resolves to Git, code, tests, or a labeled interpretation",
        "presentation/evidence/source-map.md • timeline.csv • metrics.csv • sources.md",
        notes=notes[13],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "Appendix • evidence method")
    chain = [
        (0.82, "CLAIM", "slide statement", "blue"),
        (3.35, "SOURCE", "commit + path", "cyan"),
        (5.88, "CHECK", "test / result / command", "teal"),
        (8.41, "SCOPE", "limit + date", "amber"),
        (10.94, "TYPE", "fact / interpretation", "violet"),
    ]
    for i, (x, tag, body, c) in enumerate(chain):
        s.rect(x, 2.27, 1.72, 1.42, fill=tint(c, 0.90), line=c, radius=0.16)
        s.text(x + 0.12, 2.55, 1.48, 0.30, tag, size=14, bold=True, color=c, align="center")
        s.text(x + 0.12, 3.07, 1.48, 0.25, body, size=9.3, color="muted", align="center")
        if i < len(chain) - 1:
            s.line(x + 1.77, 2.98, x + 2.42, 2.98, color="gray2", width=1.5, arrow="end")
    label_block(s, 1.02, 4.48, 3.38, 1.40, "Complete history", "542 total = 542 first-parent\n0 tags • 0 merge commits", "blue")
    label_block(s, 4.72, 4.48, 3.38, 1.40, "Replacements inspected", "Deleted hooks, targets, private bundle,\nwebsite scope, native-client ownership", "red")
    label_block(s, 8.42, 4.48, 3.38, 1.40, "Conflicts resolved", "Date + scope decide precedence;\nlimits remain visible", "violet")
    add_footer(s, 13)
    slides.append(s)

    # 14
    s = Slide(
        "Milestone commits anchor the complete linear history",
        "presentation/evidence/timeline.csv • full SHAs and evidence paths in sources.md",
        notes=notes[14],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Appendix • detailed chronology")
    rows = [
        [("7f969317", "Protect", "blue"), ("805db485", "Dual client", "blue"), ("fb417282", "Observe", "cyan"), ("07351a40", "Transact", "teal")],
        [("238f022", "Guard delete", "amber"), ("4f34299", "Backup", "amber"), ("05932762", "Evaluate", "violet"), ("f6b9909", "CI", "violet")],
        [("e8b0e9a", "Fleet sync", "teal"), ("a0b74a4", "Mac engine", "magenta"), ("4209ee8", "Public Bash/tmux", "magenta"), ("6a7e177", "Client config", "magenta")],
        [("1ed9712", "Agent replace", "amber"), ("535a492", "Cowork", "green"), ("bb11854", "Instrument", "green"), ("f254295", "HEAD", "green")],
    ]
    for r, row in enumerate(rows):
        y = 1.55 + r * 1.30
        s.line(1.02, y + 0.55, 12.25, y + 0.55, color="gray2", width=1.0)
        for i, (sha, label, c) in enumerate(row):
            x = 1.12 + i * 2.82
            s.ellipse(x, y + 0.43, 0.24, 0.24, fill=c, line=c)
            s.rect(x + 0.35, y + 0.12, 2.02, 0.83, fill="white", line=c, radius=0.12)
            s.text(x + 0.50, y + 0.28, 1.72, 0.20, label, size=10.7, bold=True, color=c, align="center")
            s.text(x + 0.50, y + 0.61, 1.72, 0.16, sha, size=7.7, color="muted", align="center")
    s.text(0.84, 6.82, 11.72, 0.22, "25-event CSV includes additional acceptance and reversal commits; this slide shows only architectural anchors.", size=9.5, color="muted", align="center")
    add_footer(s, 14)
    slides.append(s)

    # 15
    s = Slide(
        "Native readiness distinguishes pass, skip, failure, and exclusion",
        "docs/audits/hpc-{cpu,accelerator,mpi,multinode-mpi}-readiness-*.json",
        notes=notes[15],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "Appendix • categorical readiness evidence, not a benchmark")
    legend = [("Pass", "green"), ("Declared skip / no route", "amber"), ("Environment failure", "red"), ("Excluded", "darkgray")]
    for i, (t, c) in enumerate(legend):
        x = 0.80 + i * 2.73
        s.rect(x, 1.43, 0.30, 0.22, fill=c, line=c, radius=0.05)
        s.text(x + 0.42, 1.44, 2.10, 0.18, t, size=9.2, color="muted")
    matrix = [
        ("CPU", 7, 0, 0, 0, "compiler • Python • CTest"),
        ("Accelerator runtime", 7, 0, 0, 0, "5 CUDA kernels + 2 toolkit skips"),
        ("Single-node MPI", 5, 2, 0, 0, "two ranks; one node"),
        ("Multi-node MPI", 3, 0, 2, 2, "two ranks; two hosts"),
    ]
    max_total = 7
    for i, (name, pas, skip, fail, excl, scope) in enumerate(matrix):
        y = 2.15 + i * 1.08
        s.text(0.82, y + 0.12, 2.24, 0.27, name, size=13, bold=True, color="ink")
        s.text(0.82, y + 0.49, 2.24, 0.19, scope, size=8.8, color="muted")
        x = 3.22
        total_w = 8.35
        segments = [(pas, "green"), (skip, "amber"), (fail, "red"), (excl, "darkgray")]
        cursor = x
        for count, c in segments:
            if not count:
                continue
            w = total_w * count / max_total
            s.rect(cursor, y, w, 0.72, fill=c, line="white", radius=0.05)
            s.text(cursor + 0.06, y + 0.22, max(0.2, w - 0.12), 0.22, str(count), size=12, bold=True, color="white", align="center")
            cursor += w
        s.text(11.80, y + 0.22, 0.53, 0.22, f"{pas}/7", size=11, bold=True, color="green", align="right")
    s.rect(0.82, 6.56, 11.50, 0.38, fill=tint("amber", 0.90), line="amber", radius=0.10)
    s.text(1.02, 6.66, 11.10, 0.16, "NO LATENCY • BANDWIDTH • SCALING • GPU-AWARE MPI • PRODUCTION-TRAINING CLAIM", size=8.8, bold=True, color="amber", align="center")
    add_footer(s, 15)
    slides.append(s)

    # 16
    s = Slide(
        "Safety evolved from collision refusal to revalidated lifecycle controls",
        "7f969317 • 07351a40 • 238f022 • 4f34299 • e8b0e9ae • 535a492",
        notes=notes[16],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Appendix • each layer answers a different failure mode")
    layers = [
        (1, "Collision refusal", "Do not overwrite unmanaged paths", "blue"),
        (2, "Recorded preimages", "Rollback only unchanged managed state", "teal"),
        (3, "Guarded manifests", "Revalidate recursive deletion boundaries", "amber"),
        (4, "Check + restore", "Prove recovery before lifecycle progression", "violet"),
        (5, "Ancestry + bundle hash", "Keep fleet distribution clean and retry-safe", "magenta"),
        (6, "Seals + receipts", "Bind staged cross-client evidence bytes", "green"),
    ]
    for i, (num, title, body, c) in enumerate(layers):
        y = 1.46 + i * 0.88
        x = 0.84 + i * 0.12
        w = 11.62 - i * 0.24
        s.rect(x, y, w, 0.70, fill=tint(c, 0.91), line=c, radius=0.14)
        s.ellipse(x + 0.18, y + 0.16, 0.38, 0.38, fill=c, line=c)
        s.text(x + 0.18, y + 0.25, 0.38, 0.16, str(num), size=9, bold=True, color="white", align="center")
        s.text(x + 0.72, y + 0.14, 2.52, 0.24, title, size=12.2, bold=True, color=c)
        s.text(x + 3.40, y + 0.15, w - 3.70, 0.25, body, size=10.3, color="muted")
    s.rect(1.52, 6.82, 10.28, 0.18, fill="gray", line="gray2", radius=0.08, dash=True)
    s.text(1.70, 6.78, 9.92, 0.22, "Bounded controls, not a universal security boundary", size=9.3, bold=True, color="muted", align="center")
    add_footer(s, 16)
    slides.append(s)

    # 17
    s = Slide(
        "Current commands follow one plan–apply–verify grammar",
        "f254295: bin/harness • README.md • history_metrics.py --check",
        notes=notes[17],
    )
    s.rect(0, 0, W_IN, H_IN, fill="white", line="white")
    add_title(s, "Appendix • 43 user commands grouped by control role")
    groups = [
        (0.72, 1.50, 3.82, 2.12, "OBSERVE", "inventory • plan • doctor\nmacos-inventory • storage-readiness", "cyan"),
        (4.75, 1.50, 3.82, 2.12, "CONTROL", "apply • shell • tool • runtime\npython • agent • build-tool", "teal"),
        (8.78, 1.50, 3.82, 2.12, "RECOVER", "rollback • restic-primary\nrestic-schedule • replica", "amber"),
        (0.72, 3.90, 3.82, 2.12, "DISTRIBUTE", "fleet-sync • Mac update/catch-up\nagent-config-fleet", "magenta"),
        (4.75, 3.90, 3.82, 2.12, "COLLABORATE", "shared skills • durable ledger\nCodex–Claude cowork", "green"),
        (8.78, 3.90, 3.82, 2.12, "SAFETY", "guarded-delete • exact remediation\npublic audit • source contract", "red"),
    ]
    for x, y, w, h, title, body, c in groups:
        card(s, x, y, w, h, fill=tint(c, 0.95), line=c)
        pill(s, x + 0.24, y + 0.23, 1.40, title, c)
        s.text(x + 0.28, y + 0.90, w - 0.56, 0.67, body, size=12, bold=True, color="ink", align="center", min_size=10)
        s.text(x + 0.28, y + 1.70, w - 0.56, 0.20, "plan by default • explicit live gate", size=8.8, color="muted", align="center")
    add_footer(s, 17)
    slides.append(s)

    # 18
    s = Slide(
        "Evidence limits define what this deck does not claim",
        "source-map.md • evaluation/HPC/backup/cowork limitation sections",
        notes=notes[18],
    )
    s.rect(0, 0, W_IN, H_IN, fill="light", line="light")
    add_title(s, "Use these boundaries during Q&A")
    pairs = [
        ("Readiness", "Performance or scaling", "cyan"),
        ("Deterministic corpus score", "Universal agent quality", "violet"),
        ("Hashes + receipts", "Model authorship or honesty", "green"),
        ("Workspace-write", "Read confidentiality", "blue"),
        ("Verified restore", "Retention deletion authority", "amber"),
        ("Checked-in HEAD state", "Future external state", "magenta"),
    ]
    s.text(0.88, 1.48, 4.70, 0.26, "SUPPORTED CLAIM", size=10.5, bold=True, color="muted", align="center")
    s.text(7.05, 1.48, 4.95, 0.26, "NOT CLAIMED", size=10.5, bold=True, color="muted", align="center")
    for i, (yes, no, c) in enumerate(pairs):
        y = 1.90 + i * 0.78
        s.rect(0.88, y, 4.70, 0.56, fill=tint(c, 0.90), line=c, radius=0.12)
        s.text(1.08, y + 0.16, 4.30, 0.22, yes, size=11.5, bold=True, color=c, align="center")
        s.line(5.78, y + 0.28, 6.73, y + 0.28, color="gray2", width=1.4, arrow="end")
        s.rect(7.02, y, 5.00, 0.56, fill="white", line="gray2", radius=0.12, dash=True)
        s.text(7.22, y + 0.16, 4.60, 0.22, no, size=11.2, color="darkgray", align="center")
    s.rect(0.88, 6.72, 11.14, 0.24, fill="navy", line="navy", radius=0.10)
    s.text(1.10, 6.76, 10.70, 0.15, "Precision about limits is part of the harness architecture—not an appendix afterthought.", size=8.8, bold=True, color="white", align="center")
    add_footer(s, 18)
    slides.append(s)

    # Footers for slide 1 after all content.
    add_footer(slides[0], 1)
    return slides


def wrap_and_fit(text: str, w_in: float, h_in: float, size: float, bold: bool, italic: bool, min_size: float) -> tuple[str, float]:
    max_w = max(1, round(w_in * PX_PER_IN))
    max_h = max(1, round(h_in * PX_PER_IN))
    trial = size
    while trial >= min_size - 0.01:
        f = font(trial, bold, italic)
        wrapped_lines: list[str] = []
        for paragraph in text.split("\n"):
            if not paragraph:
                wrapped_lines.append("")
                continue
            words = paragraph.split()
            line = ""
            for word in words:
                candidate = word if not line else f"{line} {word}"
                if f.getlength(candidate) <= max_w:
                    line = candidate
                else:
                    if line:
                        wrapped_lines.append(line)
                    line = word
            wrapped_lines.append(line)
        line_height = round(trial * PX_PER_IN / 72 * 1.18)
        if len(wrapped_lines) * line_height <= max_h:
            return "\n".join(wrapped_lines), trial
        trial -= 0.5
    return text, min_size


def render_slide(slide: Slide, path: Path) -> list[str]:
    img = Image.new("RGB", (W_PX, H_PX), rgb("navy" if slide.dark else "white"))
    draw = ImageDraw.Draw(img, "RGBA")
    warnings: list[str] = []
    for elem in slide.elements:
        x, y, w, h = [round(v * PX_PER_IN) for v in (elem.x, elem.y, elem.w, elem.h)]
        p = elem.props
        if elem.kind == "rect":
            fill = rgb(p.get("fill", "white")) + (round(255 * (1 - p.get("alpha", 0) / 100)),)
            line = rgb(p.get("line", p.get("fill", "white"))) + (255,)
            width = max(1, round(p.get("line_width", 1) * PX_PER_IN / 72))
            radius = round(p.get("radius", 0) * PX_PER_IN)
            if p.get("dash"):
                draw.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=fill)
                dash = 10
                for xx in range(x, x + w, dash * 2):
                    draw.line((xx, y, min(xx + dash, x + w), y), fill=line, width=width)
                    draw.line((xx, y + h, min(xx + dash, x + w), y + h), fill=line, width=width)
                for yy in range(y, y + h, dash * 2):
                    draw.line((x, yy, x, min(yy + dash, y + h)), fill=line, width=width)
                    draw.line((x + w, yy, x + w, min(yy + dash, y + h)), fill=line, width=width)
            else:
                draw.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=fill, outline=line, width=width)
        elif elem.kind == "ellipse":
            fill = rgb(p.get("fill", "white")) + (255,)
            line = rgb(p.get("line", p.get("fill", "white"))) + (255,)
            width = max(1, round(p.get("line_width", 1) * PX_PER_IN / 72))
            draw.ellipse((x, y, x + w, y + h), fill=fill, outline=line, width=width)
        elif elem.kind == "line":
            x2, y2 = x + w, y + h
            color = rgb(p.get("color", "darkgray")) + (255,)
            width = max(1, round(p.get("width", 1) * PX_PER_IN / 72))
            draw.line((x, y, x2, y2), fill=color, width=width)
            arrow = p.get("arrow")
            if arrow in {"end", "both"}:
                draw_arrow(draw, x, y, x2, y2, color, width)
            if arrow == "both":
                draw_arrow(draw, x2, y2, x, y, color, width)
        elif elem.kind == "text":
            original = p["text"]
            size = p.get("size", 14)
            bold = p.get("bold", False)
            italic = p.get("italic", False)
            min_size = p.get("min_size", max(6.5, size - 4))
            wrapped, fitted = wrap_and_fit(original, elem.w, elem.h, size, bold, italic, min_size)
            p["render_text"] = wrapped
            p["render_size"] = fitted
            f = font(fitted, bold, italic)
            color = rgb(p.get("color", "ink")) + (255,)
            align = p.get("align", "left")
            anchor = p.get("valign", "top")
            spacing = max(0, round(fitted * PX_PER_IN / 72 * 0.18))
            bbox = draw.multiline_textbbox((0, 0), wrapped, font=f, spacing=spacing, align=align)
            tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
            tx = x if align == "left" else x + (w - tw) / 2 if align == "center" else x + w - tw
            ty = y if anchor == "top" else y + (h - th) / 2 if anchor == "middle" else y + h - th
            if tw > w + 3 or th > h + 3:
                warnings.append(f"text overflow: {original[:50]!r} ({tw}x{th} > {w}x{h})")
            draw.multiline_text((tx, ty), wrapped, font=f, fill=color, spacing=spacing, align=align)
        elif elem.kind == "image":
            source = Image.open(p["path"]).convert("RGB")
            if p.get("crop") == "cover":
                target_ratio = w / h
                src_ratio = source.width / source.height
                if src_ratio > target_ratio:
                    new_w = round(source.height * target_ratio)
                    left = (source.width - new_w) // 2
                    source = source.crop((left, 0, left + new_w, source.height))
                else:
                    new_h = round(source.width / target_ratio)
                    top = (source.height - new_h) // 2
                    source = source.crop((0, top, source.width, top + new_h))
            img.paste(source.resize((w, h), Image.Resampling.LANCZOS), (x, y))
        if elem.x < -0.001 or elem.y < -0.001 or elem.x + elem.w > W_IN + 0.01 or elem.y + elem.h > H_IN + 0.01:
            warnings.append(f"out of bounds: {elem.kind} at {elem.x},{elem.y},{elem.w},{elem.h}")
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, quality=95)
    return warnings


def draw_arrow(draw: ImageDraw.ImageDraw, x1: int, y1: int, x2: int, y2: int, color: tuple[int, int, int, int], width: int) -> None:
    angle = math.atan2(y2 - y1, x2 - x1)
    size = max(8, width * 4)
    points = [
        (x2, y2),
        (x2 - size * math.cos(angle - 0.45), y2 - size * math.sin(angle - 0.45)),
        (x2 - size * math.cos(angle + 0.45), y2 - size * math.sin(angle + 0.45)),
    ]
    draw.polygon(points, fill=color)


def xml_shape(elem: Element, shape_id: int, rels: dict[str, str]) -> tuple[str, int]:
    p = elem.props
    x, y, w, h = emu(elem.x), emu(elem.y), emu(abs(elem.w)), emu(abs(elem.h))
    name = f"{elem.kind.title()} {shape_id}"
    if elem.kind in {"rect", "ellipse"}:
        geom = "ellipse" if elem.kind == "ellipse" else "roundRect" if p.get("radius", 0) else "rect"
        fill = COLORS.get(p.get("fill", "white"), p.get("fill", "FFFFFF"))
        line = COLORS.get(p.get("line", p.get("fill", "white")), p.get("line", "FFFFFF"))
        alpha = p.get("alpha", 0)
        fill_xml = f'<a:solidFill><a:srgbClr val="{fill}">' + (f'<a:alpha val="{round((100-alpha)*1000)}"/>' if alpha else "") + "</a:srgbClr></a:solidFill>"
        line_width = round(p.get("line_width", 1) * 12700)
        dash = '<a:prstDash val="dash"/>' if p.get("dash") else ""
        return (
            f'<p:sp><p:nvSpPr><p:cNvPr id="{shape_id}" name="{name}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>'
            f'<p:spPr><a:xfrm><a:off x="{x}" y="{y}"/><a:ext cx="{w}" cy="{h}"/></a:xfrm>'
            f'<a:prstGeom prst="{geom}"><a:avLst/></a:prstGeom>{fill_xml}'
            f'<a:ln w="{line_width}"><a:solidFill><a:srgbClr val="{line}"/></a:solidFill>{dash}</a:ln></p:spPr>'
            f'<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="en-US"/></a:p></p:txBody></p:sp>',
            shape_id + 1,
        )
    if elem.kind == "line":
        x2, y2 = emu(elem.x + elem.w), emu(elem.y + elem.h)
        flip_h = x2 < x
        flip_v = y2 < y
        off_x, off_y = min(x, x2), min(y, y2)
        ext_x, ext_y = abs(x2 - x), abs(y2 - y)
        color = COLORS.get(p.get("color", "darkgray"), p.get("color", "334155"))
        width = round(p.get("width", 1) * 12700)
        arrow = p.get("arrow")
        head = '<a:headEnd type="triangle"/>' if arrow == "both" else ""
        tail = '<a:tailEnd type="triangle"/>' if arrow in {"end", "both"} else ""
        return (
            f'<p:cxnSp><p:nvCxnSpPr><p:cNvPr id="{shape_id}" name="{name}"/><p:cNvCxnSpPr/><p:nvPr/></p:nvCxnSpPr>'
            f'<p:spPr><a:xfrm flipH="{str(flip_h).lower()}" flipV="{str(flip_v).lower()}"><a:off x="{off_x}" y="{off_y}"/><a:ext cx="{ext_x}" cy="{ext_y}"/></a:xfrm>'
            f'<a:prstGeom prst="line"><a:avLst/></a:prstGeom><a:ln w="{width}"><a:solidFill><a:srgbClr val="{color}"/></a:solidFill>{head}{tail}</a:ln></p:spPr></p:cxnSp>',
            shape_id + 1,
        )
    if elem.kind == "text":
        text = p.get("render_text", p["text"])
        size = p.get("render_size", p.get("size", 14))
        color = COLORS.get(p.get("color", "ink"), p.get("color", "14213D"))
        bold = "1" if p.get("bold") else "0"
        italic = "1" if p.get("italic") else "0"
        align = {"left": "l", "center": "ctr", "right": "r"}.get(p.get("align", "left"), "l")
        valign = {"top": "t", "middle": "ctr", "bottom": "b"}.get(p.get("valign", "top"), "t")
        paragraphs = []
        for line in text.split("\n"):
            if line:
                paragraphs.append(
                    f'<a:p><a:pPr algn="{align}"/><a:r><a:rPr lang="en-US" sz="{round(size*100)}" b="{bold}" i="{italic}" dirty="0"><a:solidFill><a:srgbClr val="{color}"/></a:solidFill><a:latin typeface="{PPT_FONT}"/></a:rPr><a:t>{esc(line)}</a:t></a:r><a:endParaRPr lang="en-US" sz="{round(size*100)}"/></a:p>'
                )
            else:
                paragraphs.append(f'<a:p><a:pPr algn="{align}"/><a:endParaRPr lang="en-US" sz="{round(size*100)}"/></a:p>')
        return (
            f'<p:sp><p:nvSpPr><p:cNvPr id="{shape_id}" name="{name}"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>'
            f'<p:spPr><a:xfrm><a:off x="{x}" y="{y}"/><a:ext cx="{w}" cy="{h}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></p:spPr>'
            f'<p:txBody><a:bodyPr wrap="square" anchor="{valign}" lIns="0" rIns="0" tIns="0" bIns="0"/><a:lstStyle/>{"".join(paragraphs)}</p:txBody></p:sp>',
            shape_id + 1,
        )
    if elem.kind == "image":
        source = Path(p["path"])
        key = str(source.resolve())
        if key not in rels:
            rels[key] = f"rId{len(rels)+2}"
        rid = rels[key]
        return (
            f'<p:pic><p:nvPicPr><p:cNvPr id="{shape_id}" name="{esc(source.name)}"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>'
            f'<p:blipFill><a:blip r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>'
            f'<p:spPr><a:xfrm><a:off x="{x}" y="{y}"/><a:ext cx="{w}" cy="{h}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic>',
            shape_id + 1,
        )
    raise ValueError(elem.kind)


def group_props() -> str:
    return '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'


def slide_xml(slide: Slide) -> tuple[str, dict[str, str]]:
    rels: dict[str, str] = {}
    shapes = [group_props()]
    shape_id = 2
    for elem in slide.elements:
        shape, shape_id = xml_shape(elem, shape_id, rels)
        shapes.append(shape)
    bg = COLORS["navy" if slide.dark else "white"]
    xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
        f'<p:cSld><p:bg><p:bgPr><a:solidFill><a:srgbClr val="{bg}"/></a:solidFill><a:effectLst/></p:bgPr></p:bg><p:spTree>{"".join(shapes)}</p:spTree></p:cSld>'
        '<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>'
    )
    return xml, rels


def notes_xml(notes: str) -> str:
    clean = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", notes)
    paragraphs = []
    for para in re.split(r"\n\s*\n", clean):
        line = " ".join(x.strip() for x in para.splitlines()).strip()
        if not line:
            continue
        paragraphs.append(
            f'<a:p><a:r><a:rPr lang="en-US" sz="1200"><a:latin typeface="{PPT_FONT}"/></a:rPr><a:t>{esc(line)}</a:t></a:r><a:endParaRPr lang="en-US" sz="1200"/></a:p>'
        )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:notes xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
        f'<p:cSld><p:spTree>{group_props()}'
        '<p:sp><p:nvSpPr><p:cNvPr id="2" name="Notes Placeholder 1"/><p:cNvSpPr txBox="1"/><p:nvPr><p:ph type="body" idx="1"/></p:nvPr></p:nvSpPr>'
        '<p:spPr><a:xfrm><a:off x="685800" y="4114800"/><a:ext cx="5486400" cy="2286000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></p:spPr>'
        f'<p:txBody><a:bodyPr/><a:lstStyle/>{"".join(paragraphs)}</p:txBody></p:sp>'
        '</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:notes>'
    )


def theme_xml() -> str:
    return f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Harness Technical">
  <a:themeElements>
    <a:clrScheme name="Harness">
      <a:dk1><a:srgbClr val="{COLORS['navy']}"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="{COLORS['ink']}"/></a:dk2><a:lt2><a:srgbClr val="{COLORS['light']}"/></a:lt2>
      <a:accent1><a:srgbClr val="{COLORS['blue']}"/></a:accent1><a:accent2><a:srgbClr val="{COLORS['cyan']}"/></a:accent2>
      <a:accent3><a:srgbClr val="{COLORS['teal']}"/></a:accent3><a:accent4><a:srgbClr val="{COLORS['amber']}"/></a:accent4>
      <a:accent5><a:srgbClr val="{COLORS['violet']}"/></a:accent5><a:accent6><a:srgbClr val="{COLORS['green']}"/></a:accent6>
      <a:hlink><a:srgbClr val="0563C1"/></a:hlink><a:folHlink><a:srgbClr val="954F72"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Arial"><a:majorFont><a:latin typeface="{PPT_FONT}"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont><a:minorFont><a:latin typeface="{PPT_FONT}"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont></a:fontScheme>
    <a:fmtScheme name="Harness"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme>
  </a:themeElements><a:objectDefaults/><a:extraClrSchemeLst/>
</a:theme>'''


def build_pptx(slides: list[Slide]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    parts: dict[str, bytes] = {}
    def put(name: str, content: str | bytes) -> None:
        parts[name] = content.encode("utf-8") if isinstance(content, str) else content

    put("_rels/.rels", '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''')
    put("docProps/core.xml", '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Harness evolution</dc:title><dc:subject>Sourced architecture evolution</dc:subject><dc:creator>OpenAI Codex</dc:creator><cp:lastModifiedBy>OpenAI Codex</cp:lastModifiedBy><dcterms:created xsi:type="dcterms:W3CDTF">2026-07-21T00:00:00Z</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">2026-07-21T00:00:00Z</dcterms:modified></cp:coreProperties>''')
    titles = "".join(f"<vt:lpstr>{esc(s.title)}</vt:lpstr>" for s in slides)
    put("docProps/app.xml", f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>Microsoft Office PowerPoint</Application><PresentationFormat>Widescreen</PresentationFormat><Slides>{len(slides)}</Slides><Notes>{len(slides)}</Notes><HiddenSlides>0</HiddenSlides><ScaleCrop>false</ScaleCrop><HeadingPairs><vt:vector size="2" baseType="variant"><vt:variant><vt:lpstr>Slide Titles</vt:lpstr></vt:variant><vt:variant><vt:i4>{len(slides)}</vt:i4></vt:variant></vt:vector></HeadingPairs><TitlesOfParts><vt:vector size="{len(slides)}" baseType="lpstr">{titles}</vt:vector></TitlesOfParts><Company></Company><LinksUpToDate>false</LinksUpToDate><SharedDoc>false</SharedDoc><HyperlinksChanged>false</HyperlinksChanged><AppVersion>16.0000</AppVersion></Properties>''')

    # Master/layout/theme.
    put("ppt/theme/theme1.xml", theme_xml())
    put("ppt/slideMasters/slideMaster1.xml", f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree>{group_props()}</p:spTree></p:cSld><p:clrMap accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" bg1="lt1" bg2="lt2" folHlink="folHlink" hlink="hlink" tx1="dk1" tx2="dk2"/><p:sldLayoutIdLst><p:sldLayoutId id="1" r:id="rId1"/></p:sldLayoutIdLst><p:txStyles><p:titleStyle><a:lvl1pPr algn="l"><a:defRPr sz="2800" b="1"><a:latin typeface="{PPT_FONT}"/></a:defRPr></a:lvl1pPr></p:titleStyle><p:bodyStyle><a:lvl1pPr><a:defRPr sz="1600"><a:latin typeface="{PPT_FONT}"/></a:defRPr></a:lvl1pPr></p:bodyStyle><p:otherStyle><a:defPPr><a:defRPr lang="en-US"/></a:defPPr></p:otherStyle></p:txStyles></p:sldMaster>''')
    put("ppt/slideMasters/_rels/slideMaster1.xml.rels", '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/></Relationships>''')
    put("ppt/slideLayouts/slideLayout1.xml", f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank" preserve="1"><p:cSld name="Blank"><p:spTree>{group_props()}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>''')
    put("ppt/slideLayouts/_rels/slideLayout1.xml.rels", '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/></Relationships>''')
    put("ppt/notesMasters/notesMaster1.xml", f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:notesMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree>{group_props()}</p:spTree></p:cSld><p:clrMap accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" bg1="lt1" bg2="lt2" folHlink="folHlink" hlink="hlink" tx1="dk1" tx2="dk2"/><p:hf hdr="1" ftr="1" dt="1" sldNum="1"/><p:notesStyle><a:lvl1pPr><a:defRPr sz="1200"><a:latin typeface="{PPT_FONT}"/></a:defRPr></a:lvl1pPr></p:notesStyle></p:notesMaster>''')
    put("ppt/notesMasters/_rels/notesMaster1.xml.rels", '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/></Relationships>''')

    slide_ids = []
    pres_rels = [
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>',
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesMaster" Target="notesMasters/notesMaster1.xml"/>',
    ]
    image_map: dict[str, str] = {}
    for i, slide in enumerate(slides, 1):
        xml, image_rels = slide_xml(slide)
        put(f"ppt/slides/slide{i}.xml", xml)
        rel_lines = [
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>'
        ]
        for source_key, rid in image_rels.items():
            if source_key not in image_map:
                ext = Path(source_key).suffix.lower().lstrip(".")
                image_map[source_key] = f"image{len(image_map)+1}.{ext}"
            target = image_map[source_key]
            rel_lines.append(f'<Relationship Id="{rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/{target}"/>')
        note_rid = f"rId{len(image_rels)+2}"
        rel_lines.append(f'<Relationship Id="{note_rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesSlide" Target="../notesSlides/notesSlide{i}.xml"/>')
        put(f"ppt/slides/_rels/slide{i}.xml.rels", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + "".join(rel_lines) + "</Relationships>")
        put(f"ppt/notesSlides/notesSlide{i}.xml", notes_xml(slide.notes))
        put(f"ppt/notesSlides/_rels/notesSlide{i}.xml.rels", f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesMaster" Target="../notesMasters/notesMaster1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="../slides/slide{i}.xml"/></Relationships>''')
        rid = i + 2
        slide_ids.append(f'<p:sldId id="{255+i}" r:id="rId{rid}"/>')
        pres_rels.append(f'<Relationship Id="rId{rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide{i}.xml"/>')

    for source, target in image_map.items():
        put(f"ppt/media/{target}", Path(source).read_bytes())

    put("ppt/presentation.xml", f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst><p:notesMasterIdLst><p:notesMasterId r:id="rId2"/></p:notesMasterIdLst><p:sldIdLst>{''.join(slide_ids)}</p:sldIdLst><p:sldSz cx="{emu(W_IN)}" cy="{emu(H_IN)}" type="screen16x9"/><p:notesSz cx="6858000" cy="9144000"/><p:defaultTextStyle><a:defPPr><a:defRPr lang="en-US"/></a:defPPr></p:defaultTextStyle></p:presentation>''')
    put("ppt/_rels/presentation.xml.rels", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + "".join(pres_rels) + "</Relationships>")

    overrides = [
        ('/ppt/presentation.xml', 'application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml'),
        ('/ppt/slideMasters/slideMaster1.xml', 'application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml'),
        ('/ppt/slideLayouts/slideLayout1.xml', 'application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml'),
        ('/ppt/theme/theme1.xml', 'application/vnd.openxmlformats-officedocument.theme+xml'),
        ('/ppt/notesMasters/notesMaster1.xml', 'application/vnd.openxmlformats-officedocument.presentationml.notesMaster+xml'),
        ('/docProps/core.xml', 'application/vnd.openxmlformats-package.core-properties+xml'),
        ('/docProps/app.xml', 'application/vnd.openxmlformats-officedocument.extended-properties+xml'),
    ]
    for i in range(1, len(slides) + 1):
        overrides.append((f'/ppt/slides/slide{i}.xml', 'application/vnd.openxmlformats-officedocument.presentationml.slide+xml'))
        overrides.append((f'/ppt/notesSlides/notesSlide{i}.xml', 'application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml'))
    override_xml = "".join(f'<Override PartName="{p}" ContentType="{t}"/>' for p, t in overrides)
    put("[Content_Types].xml", f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Default Extension="jpg" ContentType="image/jpeg"/><Default Extension="jpeg" ContentType="image/jpeg"/>{override_xml}</Types>''')

    tmp = PPTX.with_suffix(".pptx.tmp")
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zf:
        for name, content in sorted(parts.items()):
            zf.writestr(name, content)
    tmp.replace(PPTX)


def verify_pptx(slides: list[Slide]) -> list[str]:
    errors: list[str] = []
    with zipfile.ZipFile(PPTX) as zf:
        names = set(zf.namelist())
        if zf.testzip() is not None:
            errors.append("zip CRC failure")
        required = {"[Content_Types].xml", "ppt/presentation.xml", "ppt/slideMasters/slideMaster1.xml"}
        required |= {f"ppt/slides/slide{i}.xml" for i in range(1, len(slides) + 1)}
        required |= {f"ppt/notesSlides/notesSlide{i}.xml" for i in range(1, len(slides) + 1)}
        missing = sorted(required - names)
        if missing:
            errors.append(f"missing parts: {missing}")
        for name in names:
            if name.endswith((".xml", ".rels")):
                try:
                    ET.fromstring(zf.read(name))
                except ET.ParseError as exc:
                    errors.append(f"invalid XML {name}: {exc}")
        # Resolve internal relationship targets.
        rel_ns = {"r": "http://schemas.openxmlformats.org/package/2006/relationships"}
        for rel_name in (n for n in names if n.endswith(".rels")):
            root = ET.fromstring(zf.read(rel_name))
            rel_path = PurePosixPath(rel_name)
            if rel_name == "_rels/.rels":
                source_dir = PurePosixPath("")
            else:
                source_dir = rel_path.parent.parent
            for rel in root.findall("r:Relationship", rel_ns):
                if rel.get("TargetMode") == "External":
                    continue
                target = rel.get("Target", "")
                resolved = str(PurePosixPath(source_dir, target))
                # Normalize ../ segments.
                parts: list[str] = []
                for part in PurePosixPath(resolved).parts:
                    if part == "..":
                        if parts:
                            parts.pop()
                    elif part != ".":
                        parts.append(part)
                normalized = "/".join(parts)
                if normalized not in names:
                    errors.append(f"broken relationship {rel_name} -> {normalized}")
        pres = ET.fromstring(zf.read("ppt/presentation.xml"))
        ns = {"p": "http://schemas.openxmlformats.org/presentationml/2006/main"}
        if len(pres.findall(".//p:sldId", ns)) != len(slides):
            errors.append("presentation slide count mismatch")
        for i in range(1, len(slides) + 1):
            note_text = zf.read(f"ppt/notesSlides/notesSlide{i}.xml").decode("utf-8")
            if "Notes Placeholder" not in note_text or "<a:t>" not in note_text:
                errors.append(f"slide {i} notes missing")
    return errors


def contact_sheet(slides: list[Slide]) -> None:
    thumbs = []
    for i in range(1, len(slides) + 1):
        img = Image.open(RENDER_DIR / f"slide-{i:02d}.png").convert("RGB")
        img.thumbnail((480, 270), Image.Resampling.LANCZOS)
        thumbs.append(img.copy())
    cols = 3
    rows = math.ceil(len(thumbs) / cols)
    sheet = Image.new("RGB", (cols * 500, rows * 300), (235, 239, 246))
    draw = ImageDraw.Draw(sheet)
    for i, img in enumerate(thumbs):
        x = (i % cols) * 500 + 10
        y = (i // cols) * 300 + 10
        sheet.paste(img, (x, y))
        draw.text((x, y + 273), f"Slide {i+1}", font=font(9, bold=True), fill=rgb("muted"))
    sheet.save(OUT / "contact-sheet.png")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    slides = build_slides()
    if len(slides) != 18:
        raise SystemExit(f"expected 18 slides, got {len(slides)}")
    warnings: list[str] = []
    if not args.verify_only:
        if RENDER_DIR.exists():
            for path in RENDER_DIR.glob("slide-*.png"):
                path.unlink()
        RENDER_DIR.mkdir(parents=True, exist_ok=True)
        for i, slide in enumerate(slides, 1):
            warnings.extend(f"slide {i}: {warning}" for warning in render_slide(slide, RENDER_DIR / f"slide-{i:02d}.png"))
        build_pptx(slides)
        contact_sheet(slides)
    errors = verify_pptx(slides)
    if warnings:
        print("RENDER WARNINGS")
        print("\n".join(warnings))
    if errors:
        print("PPTX ERRORS")
        print("\n".join(errors))
        return 1
    print(f"slides={len(slides)} pptx={PPTX} size={PPTX.stat().st_size} render_warnings={len(warnings)}")
    return 0 if not warnings else 2


if __name__ == "__main__":
    raise SystemExit(main())
