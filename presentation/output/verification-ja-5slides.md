# 日本語5枚版 presentation verification

Verified on 2026-07-21 against source snapshot
`90451d49ac96a31ca5f42044ce2f4735b8908698`.

## Artifact checks

- 5-slide editable 16:9 OOXML PowerPointを生成した。
- architecture、incident flow、timeline、metric cards、bars、labelsはnative
  PowerPoint shapes/text/connectorsで構成し、slide contentにraster imageは使用していない。
- 5枚すべてにembedded notes partを持たせ、同内容を
  `speaker-notes-ja-5slides.md`にも保存した。
- PPTX CRC、全XML/relationship、5 slide parts、5 notes parts、16:9 dimensions、
  `Yu Gothic` font declarationを検証した。
- 5枚すべてを1920×1080で個別に確認した。Slides 1/3/4/5の構造改訂後に
  未対応glyph 1件を修正し、final renderer warningは0。
- `contact-sheet-ja-5slides.png`をfinal renderの一覧として保存した。
- owner指定どおりSlide 2を固定し、改訂前後でrender PNG、slide XML、notes XMLの
  SHA-256がそれぞれ完全一致することを検証した。
- clean treeで`tests/test-phase1.sh`を実行し、57 focused suites、guarded-delete、
  syntax、portable gatesがpassした。native MPI smokeはdeclared MPI environment
  専用のため想定どおりskipした。

## Evidence checks

- source HEAD `90451d4`は544 total / 544 first-parent commitsとして解決した。
- storyboard、speaker notes、source mapがすべてSlide 1–5をcoverすることを確認した。
- Slide 1の7 Linux / 4 accepted Mac / 2 client topology、repository tree、skill
  invocationはcurrent profiles、installer、policy、skill inventoryと照合した。
- Slide 3のsafeguard sequenceと57 focused suiteからprotected CIまでのtest pathは
  policy、transaction/guard tests、focused runner、phase-1、CI workflowと照合した。
- Slide 4のsymmetric roles、durable `.md` session、staged exchange、restart/takeover
  semanticsはcowork SKILL、protocol、helper、focused testsと照合した。
- `rm -rf` incidentは一次記録`e5200fd`、consolidated recovery `d726f0d`、
  guarded-delete response `238f022`を分離して照合した。
- incidentのfact、architecture interpretation、forensic/recovery limitationsを
  slide上で異なるvisual encodingにした。
- current-state claimはfresh fetch/rebase後の`90451d4`へ更新し、4台のMac acceptanceを反映した。

Reproduction:

```sh
python3 presentation/scripts/build_deck_ja_5slides.py
python3 presentation/scripts/verify_presentation_ja_5slides.py
```

## Remaining human check

PowerPoint/LibreOfficeとrequested `$slides` skillが環境になかったため、editable
OOXMLと同一scene graph renderで検証した。外部配布前にMicrosoft PowerPointで
font substitution、line break、speaker notes表示を確認することが望ましい。
