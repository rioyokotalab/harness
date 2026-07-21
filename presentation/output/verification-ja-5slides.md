# 日本語5枚版 presentation verification

Verified on 2026-07-21 against source snapshot
`7c592af6a9778ce24fe36b093c3bcdccb877da61`.

## Artifact checks

- 5-slide editable 16:9 OOXML PowerPointを生成した。
- architecture、incident flow、timeline、metric cards、bars、labelsはnative
  PowerPoint shapes/text/connectorsで構成し、slide contentにraster imageは使用していない。
- 5枚すべてにembedded notes partを持たせ、同内容を
  `speaker-notes-ja-5slides.md`にも保存した。
- PPTX CRC、全XML/relationship、5 slide parts、5 notes parts、16:9 dimensions、
  `Yu Gothic` font declarationを検証した。
- 5枚すべてを1920×1080で個別に確認した。初回の4件の小さなtext overflowを
  修正し、final renderer warningは0。
- `contact-sheet-ja-5slides.png`をfinal renderの一覧として保存した。

## Evidence checks

- source HEAD `7c592af`は543 total / 543 first-parent commitsとして解決した。
- storyboard、speaker notes、source mapがすべてSlide 1–5をcoverすることを確認した。
- `rm -rf` incidentは一次記録`e5200fd`、consolidated recovery `d726f0d`、
  guarded-delete response `238f022`を分離して照合した。
- incidentのfact、architecture interpretation、forensic/recovery limitationsを
  slide上で異なるvisual encodingにした。
- current-state claimはfresh fetch後の`7c592af`へ更新し、4台のMac acceptanceを反映した。

Reproduction:

```sh
python3 presentation/scripts/build_deck_ja_5slides.py
python3 presentation/scripts/verify_presentation_ja_5slides.py
```

## Remaining human check

PowerPoint/LibreOfficeとrequested `$slides` skillが環境になかったため、editable
OOXMLと同一scene graph renderで検証した。外部配布前にMicrosoft PowerPointで
font substitution、line break、speaker notes表示を確認することが望ましい。
