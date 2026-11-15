# Golden files

`purchase_request.txt` is the expected text of the generated รายงานขอซื้อขอจ้าง for the
fixture case in `spec/support/purchase_request_fixture.rb`: one line per non-empty paragraph,
whitespace collapsed, both copies of each signature text box included.

It was reviewed line by line against the real form
(`docs/samples/ai-purchase/รายงานขอซื้อจ้าง claude .docx`, not in git) after swapping the real
names for the fictional ones in `db/seeds/reference/people.yml`. Every remaining difference is
intended:

| # | Paragraph | Real form | Generated | Why |
|---|---|---|---|---|
| 1 | เลขที่ | `สชก.(บก-ท)` | `สชก.(บก-ท)         /2569` | leaves a gap to write the number by hand, like the results report form |
| 2 | เรื่อง | split over two paragraphs | one paragraph | the item line is now one field; Word wraps it |
| 3 | ด้วย … | `… Claude Pro (Annual) รายปี …` + a manual line break | `… Claude Pro (Annual) แบบรายปี …` | the item name comes from a single field (principle 2) |
| 4 | โดย … | `ซอฟต์แวร์ Claude Pro` / `( Annual ) แบบรายปี …` in two paragraphs | one paragraph, item name from the same field | same as 3 |

Amounts (7,990 — see `docs/OPEN_QUESTIONS.md` Q1), dates, legal references and every other
sentence are identical to the form.

Regenerate after an intended change, then review the diff before committing:

```sh
UPDATE_GOLDEN=1 bundle exec rspec spec/services/document_generator_spec.rb
```

## result_report.txt

รายงานผลการพิจารณาและอนุมัติสั่งซื้อ **ไม่มีไฟล์ .docx ต้นฉบับ** (OPEN_QUESTIONS Q28) template จึงสร้างจาก
template รายงานขอซื้อ (แบบฟอร์มชุดเดียวกัน) ด้วย `script/docx/build_result_report.rb` แล้วใส่เนื้อความตาม
`docs/samples/ai-purchase/รายงานผลพิจารณา claude ai.pdf` ทุกคำ รวมคำที่น่าจะพิมพ์ผิด (Q8: "อนุมัติจ้าง ขอจัดซื้อ",
"เฉพาะเจาะจง )", "ณ วันที่ลงวันที่")

เทียบกับ text layer ของ PDF (แทนชื่อจริงและรหัสพนักงานด้วยข้อมูลสมมติ) ตรงกันทุกคำ ต่างเพียงช่องว่างที่ PDF
แทรกตรงจุดตัดบรรทัด ("โดยวิธี เฉพาะเจาะจง", "จึงเห็นควร ซื้อ", "ผู้เสนอราคา ดังกล่าว") ซึ่งในเอกสารจริงเป็นคำเดียวกัน
ตำแหน่งช่องลงนามประมาณจากภาพ PDF — ควรให้คนเปิด Word เทียบกับฉบับจริง
