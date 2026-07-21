# 日本語1枚版 presentation verification

Verified on 2026-07-21 against source snapshot
`90451d49ac96a31ca5f42044ce2f4735b8908698`.

## Artifact checks

- 旧5枚版の最終summary slideだけを残した、1-slide editable 16:9 OOXML
  PowerPointを同じdeliverable pathへ生成した。
- timeline、metric cards、reversal arrows、labelsはnative PowerPoint
  shapes/text/connectorsで構成し、slide contentにraster imageはない。
- 1 slide partと1 embedded notes part、全XML/relationship、16:9 dimensions、
  `Yu Gothic` font declarationを検証した。
- final slideを1920×1080で原寸確認し、text overflow、clipping、overlap、
  unsupported glyph、distortionはなく、renderer warningは0だった。
- render directoryにはfinal `slide-01.png`だけが残り、contact sheetも1枚だけを含む。

## Evidence checks

- source HEAD `90451d4`は544 total / 544 first-parent commitsとして解決した。
- storyboard、speaker notes、source mapはSlide 1だけをcoverする。
- history/stage、checked-in metrics、four reversals、current surface、not-claimed
  limitsを`timeline.csv`、`metrics.csv`、milestone diffs、audits、current treeと照合した。
- countsは品質指標ではなく、readiness/evaluation/timingにはcorpus・host・scope
  limitsがあることをslide、notes、source mapで明示した。
- clean treeで`tests/test-phase1.sh`を実行し、57 focused suites、guarded-delete、
  syntax、portable gatesがpassした。native MPI smokeはdeclared MPI environment
  専用のため想定どおりskipした。

Reproduction:

```sh
python3 presentation/scripts/build_deck_ja_5slides.py
python3 presentation/scripts/verify_presentation_ja_5slides.py
```

## Remaining human check

PowerPoint/LibreOfficeとrequested `$slides` skillが環境になかったため、editable
OOXMLと同一scene graph renderで検証した。外部配布前にMicrosoft PowerPointで
font substitution、line break、speaker notes表示を確認することが望ましい。
