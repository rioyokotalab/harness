#!/usr/bin/env python3
"""Verify the Japanese five-slide presentation bundle and its evidence links."""

from __future__ import annotations

import hashlib
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
FIXED_SLIDE2_PNG = "25eea4250441d76bad469d6f1ef645d62cf3c72d331bfdce235bbb6e86e71877"
FIXED_SLIDE2_XML = "de3d02d1b43097c0139fb304b7bd4822b40aa2ab632992034e0e6db137b25231"
FIXED_SLIDE2_NOTES = "fd03ce0ddfc46d360c357aa55c2660437d2e1ec1ead4b4e6626d0d54fd8aace9"


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
        EVIDENCE / "incident-rm-rf.md",
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
    expected = set(range(1, 6))
    storyboard_slides = {int(v) for v in re.findall(r"^## Slide (\d+) —", storyboard, re.M)}
    note_slides = {int(v) for v in re.findall(r"^## Slide (\d+) —", notes, re.M)}
    source_slides = {int(v) for v in re.findall(r"^\| (\d+) \|", source_map, re.M)}
    if storyboard_slides != expected or note_slides != expected or source_slides != expected:
        fail(
            "slide coverage differs: "
            f"storyboard={sorted(storyboard_slides)} notes={sorted(note_slides)} "
            f"source_map={sorted(source_slides)}"
        )

    incident = (EVIDENCE / "incident-rm-rf.md").read_text(encoding="utf-8")
    for token in ("e5200fd", "238f022", "temporary-`HOME`", "first tool cancellation"):
        if token not in incident:
            fail(f"incident evidence missing token: {token}")
    timeline = (EVIDENCE / "timeline.csv").read_text(encoding="utf-8")
    if "e5200fd3ae3aa5b6b326205b6475af2047d21929" not in timeline:
        fail("incident is absent from timeline.csv")

    with zipfile.ZipFile(PPTX) as archive:
        if archive.testzip():
            fail("PPTX CRC failure")
        names = set(archive.namelist())
        slides = [name for name in names if re.fullmatch(r"ppt/slides/slide\d+\.xml", name)]
        note_parts = [name for name in names if re.fullmatch(r"ppt/notesSlides/notesSlide\d+\.xml", name)]
        if len(slides) != 5 or len(note_parts) != 5:
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
        slide2_xml = hashlib.sha256(archive.read("ppt/slides/slide2.xml")).hexdigest()
        slide2_notes = hashlib.sha256(
            archive.read("ppt/notesSlides/notesSlide2.xml")
        ).hexdigest()
        if slide2_xml != FIXED_SLIDE2_XML or slide2_notes != FIXED_SLIDE2_NOTES:
            fail(
                "fixed Slide 2 OOXML changed: "
                f"slide={slide2_xml} notes={slide2_notes}"
            )

    renders = list((OUTPUT / "rendered-ja-5slides").glob("slide-*.png"))
    if len(renders) != 5:
        fail(f"expected five renders, found {len(renders)}")
    slide2_png = hashlib.sha256(
        (OUTPUT / "rendered-ja-5slides/slide-02.png").read_bytes()
    ).hexdigest()
    if slide2_png != FIXED_SLIDE2_PNG:
        fail(f"fixed Slide 2 render changed: {slide2_png}")

    print(
        "verification passed: source=90451d4 history=544/544 "
        "slides=5 notes=5 source_map=5 aspect=16:9 xml=valid renders=5 "
        "font=Yu-Gothic slide2=fixed"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
