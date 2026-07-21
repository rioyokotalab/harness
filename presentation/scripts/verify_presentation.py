#!/usr/bin/env python3
"""Deterministic structural and provenance checks for the presentation bundle."""

from __future__ import annotations

import csv
import re
import subprocess
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[2]
PRESENTATION = ROOT / "presentation"
EVIDENCE = PRESENTATION / "evidence"
OUTPUT = PRESENTATION / "output"
PPTX = OUTPUT / "harness-evolution.pptx"


def fail(message: str) -> None:
    raise SystemExit(f"verification failed: {message}")


def git_commit_exists(sha: str) -> bool:
    result = subprocess.run(
        ["git", "cat-file", "-e", f"{sha}^{{commit}}"],
        cwd=ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def main() -> int:
    required = [
        EVIDENCE / "timeline.csv",
        EVIDENCE / "milestones.md",
        EVIDENCE / "source-map.md",
        EVIDENCE / "metrics.csv",
        OUTPUT / "storyboard.md",
        OUTPUT / "speaker-notes.md",
        OUTPUT / "sources.md",
        PPTX,
        OUTPUT / "contact-sheet.png",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail("missing required files: " + ", ".join(missing))

    with (EVIDENCE / "timeline.csv").open(newline="", encoding="utf-8") as handle:
        timeline = list(csv.DictReader(handle))
    if not 5 <= len(timeline) <= 40:
        fail(f"unexpected timeline length: {len(timeline)}")
    unresolved = sorted({row["commit_sha"] for row in timeline if not git_commit_exists(row["commit_sha"])})
    if unresolved:
        fail("timeline contains unresolved commits: " + ", ".join(unresolved))

    with (EVIDENCE / "metrics.csv").open(newline="", encoding="utf-8") as handle:
        metrics = list(csv.DictReader(handle))
    if not metrics or any(not row["reproduction_command"].strip() for row in metrics):
        fail("metrics must be nonempty and reproducible")

    storyboard = (OUTPUT / "storyboard.md").read_text(encoding="utf-8")
    notes = (OUTPUT / "speaker-notes.md").read_text(encoding="utf-8")
    source_map = (EVIDENCE / "source-map.md").read_text(encoding="utf-8")
    storyboard_slides = {int(value) for value in re.findall(r"^### Slide (\d+) —", storyboard, re.M)}
    note_slides = {int(value) for value in re.findall(r"^## Slide (\d+) —", notes, re.M)}
    expected = set(range(1, 19))
    if storyboard_slides != expected:
        fail(f"storyboard slide coverage differs: {sorted(storyboard_slides)}")
    if note_slides != expected:
        fail(f"speaker-note coverage differs: {sorted(note_slides)}")
    main_claim_slides = {int(value) for value in re.findall(r"^\| (\d+) \|", source_map, re.M)}
    appendix_claims = set(re.findall(r"^\| (A\d+) \|", source_map, re.M))
    if main_claim_slides != set(range(1, 13)):
        fail(f"main source-map coverage differs: {sorted(main_claim_slides)}")
    if appendix_claims != {f"A{i}" for i in range(1, 7)}:
        fail(f"appendix source-map coverage differs: {sorted(appendix_claims)}")

    with zipfile.ZipFile(PPTX) as archive:
        bad = archive.testzip()
        if bad:
            fail(f"corrupt PPTX member: {bad}")
        names = set(archive.namelist())
        slides = sorted(name for name in names if re.fullmatch(r"ppt/slides/slide\d+\.xml", name))
        note_parts = sorted(name for name in names if re.fullmatch(r"ppt/notesSlides/notesSlide\d+\.xml", name))
        if len(slides) != 18 or len(note_parts) != 18:
            fail(f"PPTX has {len(slides)} slides and {len(note_parts)} notes parts")
        for name in names:
            if name.endswith(".xml") or name.endswith(".rels"):
                ElementTree.fromstring(archive.read(name))
        presentation_xml = ElementTree.fromstring(archive.read("ppt/presentation.xml"))
        ns = {"p": "http://schemas.openxmlformats.org/presentationml/2006/main"}
        size = presentation_xml.find("p:sldSz", ns)
        if size is None or (size.attrib.get("cx"), size.attrib.get("cy")) != ("12192000", "6858000"):
            fail("presentation is not 16:9 widescreen")

    render_files = list((OUTPUT / "rendered").glob("slide-*.png"))
    if len(render_files) != 18:
        fail(f"expected 18 rendered slides, found {len(render_files)}")

    metric_check = subprocess.run(
        [sys.executable, str(PRESENTATION / "scripts" / "history_metrics.py"), "--check"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if metric_check.returncode:
        fail("history metric check failed:\n" + metric_check.stdout)

    print(
        "verification passed: "
        f"timeline={len(timeline)} metrics={len(metrics)} slides=18 notes=18 "
        "source_map=12+6 aspect=16:9 xml=valid renders=18"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
