# Presentation verification

Verified on 2026-07-21 against repository HEAD
`f25429546bf8114b3309f26e3d3242feae191a30`.

## Artifact checks

- Built an editable 16:9 OOXML PowerPoint with 18 slides.
- Kept diagrams, timelines, comparison bars, labels, and metric displays as
  native PowerPoint shapes, text, and connectors. The cover artwork is the only
  raster visual used in the slide content.
- Embedded a notes part for every slide and supplied the same notes in
  `speaker-notes.md`.
- Validated the PowerPoint ZIP CRC, every XML and relationship part, 18 slide
  parts, 18 notes parts, and the 16:9 slide dimensions.
- Rendered all 18 slides at 1920×1080, inspected every slide individually, and
  corrected the current-architecture comparison after the first pass exposed an
  overlap. The final renderer reported zero text-overflow warnings.
- Created `contact-sheet.png` as a compact record of the final rendered deck.

## Evidence checks

- Resolved all 25 timeline SHAs to commits in this repository.
- Checked 31 metrics for nonempty reproduction commands, then reran
  `presentation/scripts/history_metrics.py --check`.
- Confirmed source-map coverage for all 12 main slides and all six appendix
  slides.
- Confirmed storyboard and speaker-note coverage for slides 1–18.
- Reconciled the historical/current conflicts documented in
  `source-map.md`: dated skill counts, T-181 primary versus targeted review,
  pre-publication cowork wording, and readiness versus performance claims.

Reproduction command:

```sh
python3 presentation/scripts/verify_presentation.py
```

## Environment limits

- `presentation/template.pptx` did not exist, so no repository slide master was
  available to preserve. The deck uses a presentation-specific visual system.
- Microsoft PowerPoint, LibreOffice, and the named `$slides` skill were not
  available in the environment. The deck was generated directly as standards-
  based OOXML and rendered from the same scene graph used to create the editable
  objects. An Office-application fidelity pass remains useful before external
  delivery.
- The PowerPoint requests Arial. The local visual renderer used Nimbus Sans as
  its metric-compatible fallback; a receiving system with Arial may produce
  small line-break differences.
- The checked-in evidence proves repository state and recorded acceptance at
  the cited dates. It does not revalidate mutable external hosts, schedulers,
  backup stores, or client installations as of viewing time.
