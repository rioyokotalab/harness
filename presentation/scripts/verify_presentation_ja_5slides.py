#!/usr/bin/env python3
"""Verify the single-slide Japanese presentation bundle and evidence links."""

from __future__ import annotations

import re
import subprocess
import zipfile
from pathlib import Path
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "presentation/output"
EVIDENCE = ROOT / "presentation/evidence"
PPTX = OUTPUT / "harness-evolution-ja-5slides.pptx"
SOURCE_REV = "90451d49ac96a31ca5f42044ce2f4735b8908698"


def fail(message: str) -> None:
    raise SystemExit(f"verification failed: {message}")


def main() -> int:
    required = [
        PPTX,
        OUTPUT / "storyboard-ja-5slides.md",
        OUTPUT / "speaker-notes-ja-5slides.md",
        OUTPUT / "sources-ja-5slides.md",
        OUTPUT / "contact-sheet-ja-5slides.png",
        EVIDENCE / "source-map-ja-5slides.md",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail("missing files: " + ", ".join(missing))

    if subprocess.run(
        ["git", "cat-file", "-e", f"{SOURCE_REV}^{{commit}}"], cwd=ROOT, check=False
    ).returncode:
        fail("source snapshot does not resolve")
    commits = int(
        subprocess.check_output(
            ["git", "rev-list", "--count", SOURCE_REV], cwd=ROOT, text=True
        ).strip()
    )
    first_parent = int(
        subprocess.check_output(
            ["git", "rev-list", "--first-parent", "--count", SOURCE_REV],
            cwd=ROOT,
            text=True,
        ).strip()
    )
    if (commits, first_parent) != (544, 544):
        fail(f"source-history drift: commits={commits} first_parent={first_parent}")

    storyboard = (OUTPUT / "storyboard-ja-5slides.md").read_text(encoding="utf-8")
    notes = (OUTPUT / "speaker-notes-ja-5slides.md").read_text(encoding="utf-8")
    source_map = (EVIDENCE / "source-map-ja-5slides.md").read_text(encoding="utf-8")
    expected = {1}
    storyboard_slides = {int(v) for v in re.findall(r"^## Slide (\d+) —", storyboard, re.M)}
    note_slides = {int(v) for v in re.findall(r"^## Slide (\d+) —", notes, re.M)}
    source_slides = {int(v) for v in re.findall(r"^\| (\d+) \|", source_map, re.M)}
    if storyboard_slides != expected or note_slides != expected or source_slides != expected:
        fail(
            "slide coverage differs: "
            f"storyboard={sorted(storyboard_slides)} notes={sorted(note_slides)} "
            f"source_map={sorted(source_slides)}"
        )

    with zipfile.ZipFile(PPTX) as archive:
        if archive.testzip():
            fail("PPTX CRC failure")
        names = set(archive.namelist())
        slides = [name for name in names if re.fullmatch(r"ppt/slides/slide\d+\.xml", name)]
        note_parts = [name for name in names if re.fullmatch(r"ppt/notesSlides/notesSlide\d+\.xml", name)]
        if len(slides) != 1 or len(note_parts) != 1:
            fail(f"PPTX has {len(slides)} slides and {len(note_parts)} notes parts")
        for name in names:
            if name.endswith(".xml") or name.endswith(".rels"):
                ElementTree.fromstring(archive.read(name))
        presentation = ElementTree.fromstring(archive.read("ppt/presentation.xml"))
        ns = {"p": "http://schemas.openxmlformats.org/presentationml/2006/main"}
        size = presentation.find("p:sldSz", ns)
        if size is None or (size.attrib.get("cx"), size.attrib.get("cy")) != (
            "12192000",
            "6858000",
        ):
            fail("presentation is not 16:9")
        slide_bytes = b"".join(archive.read(name) for name in slides)
        if b"Yu Gothic" not in slide_bytes:
            fail("Japanese PowerPoint font declaration is missing")

    renders = list((OUTPUT / "rendered-ja-5slides").glob("slide-*.png"))
    if len(renders) != 1:
        fail(f"expected one render, found {len(renders)}")

    print(
        "verification passed: source=90451d4 history=544/544 "
        "slides=1 notes=1 source_map=1 aspect=16:9 xml=valid renders=1 "
        "font=Yu-Gothic"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
