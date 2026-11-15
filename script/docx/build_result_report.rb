# Builds app/templates/docx/result_report.docx (รายงานผลการพิจารณาและอนุมัติสั่งซื้อ).
#
#   bundle exec ruby script/docx/build_result_report.rb
#
# EXCEPTION TO DESIGN PRINCIPLE 5: there is no original .docx for this form, only
# a PDF (docs/samples/ai-purchase/รายงานผลพิจารณา claude ai.pdf). Approved by the
# project owner on 15 Nov 2026 (OPEN_QUESTIONS Q28). To stay as close to the real
# form as possible we start from the purchase request template of the same form set
# (same logo, header table, page size, margins, fonts and paragraph styles) and only
# replace the body with the text of the PDF, word for word, except two obvious
# typos fixed per OPEN_QUESTIONS Q8 (stray ")" after เฉพาะเจาะจง, "ณ วันที่ลงวันที่").
# The subject wording "อนุมัติจ้าง ขอจัดซื้อ" is kept as the form's own wording.
# Replace this with the real .docx as soon as one is found.
require_relative "docx_template_builder"

SOURCE = File.expand_path("../../app/templates/docx/purchase_request.docx", __dir__)
TARGET = File.expand_path("../../app/templates/docx/result_report.docx", __dir__)

def f(expr) = DocxTemplateBuilder::Field.new(expr)

DocxTemplateBuilder.new(SOURCE, TARGET).build do |doc|
  # ── header table (same table as the purchase request) ──
  doc.apply(match: /\A«org\.unit_name» \(«org\.unit_code»\)\z/,
            replace: [ [ /.+/, [ f("org.unit_short"), " (", f("org.unit_code"), ")" ] ] ])
  doc.apply(match: /\A«request\.doc_number»\z/, replace: [ [ /.+/, [ f("result.doc_number") ] ] ])
  doc.apply(match: /\A«request\.doc_date_text»\z/, replace: [ [ /.+/, [ f("result.doc_date_text") ] ] ])
  doc.apply(match: /\A«request\.subject»\z/, replace: [ [ /.+/, [ f("result.subject") ] ] ])

  # ── styles taken from existing paragraphs of the form ──
  body = doc.styles_of(doc.paragraph(/\Aด้วย «org\.unit_short» มีความประสงค์/))   # first-line indent, Thai justify
  plain = doc.styles_of(doc.paragraph(/\A«org\.unit_name»\/ «org\.unit_code»\z/))     # footer line
  plain[:rpr] = body[:rpr]
  table = doc.paragraph(/\Aเรียน\z/).at_xpath("ancestor::w:tbl[1]", DocxTemplateBuilder::NS)

  # ── body, following the PDF ──
  doc.remove_body_after(table)
  blank = -> { doc.append_paragraph([], **plain) }

  blank.call
  doc.append_paragraph([
    "ตามอนุมัติรายงานขอซื้อขอจ้าง หนังสือ ", f("request.doc_number"), "  ลงวันที่  ", f("request.doc_date_text"),
    " ขอจัดซื้อ", f("item.line"), " โดยวิธีเฉพาะเจาะจง โดยอ้างอิงราคาที่ประกาศจำหน่ายบนเว็บไซต์ทางการ ",
    f("price.source_url"), "  สืบราคา ณ วันที่ ", f("price.survey_date_text"), " จำนวน ",
    f("price.reference_money"), " บาท (", f("price.reference_text"), ")  (รวมภาษีมูลค่าเพิ่ม) ",
    "ผลการพิจารณาปรากฏว่า พัสดุมีรายละเอียดถูกต้องตรงตามที่ กฟภ. กำหนด จึงเห็นควรซื้อ/จ้างจากบริษัทดังกล่าวข้างต้น ",
    "และเห็นควรให้", f("people.borrower.display_name"), " ", f("people.borrower.position_with_unit"),
    " (", f("people.borrower.employee_code"), ") เป็นผู้ยืมเงินจำนวนเงินดังกล่าวจาก ", f("loan.lender_unit")
  ], **body)
  doc.append_paragraph(
    [ "จึงเรียนมาเพื่อโปรดพิจารณา หากเห็นชอบโปรดลงนามอนุมัติให้สั่งซื้อสั่งจ้างจากผู้เสนอราคาดังกล่าวต่อไป" ], **body
  )

  2.times { blank.call }
  requester_block = { "ind" => { "left" => "4536" }, "jc" => { "val" => "center" } } # right half, centred
  doc.append_paragraph([ "(", f("people.requester.display_name"), ")" ], **plain, ppr_set: requester_block)
  doc.append_paragraph([ f("people.requester.position_en") ], **plain, ppr_set: requester_block)

  2.times { blank.call }
  doc.append_paragraph([ "อนุมัติสั่งซื้อสั่งจ้าง" ], **plain, ppr_set: { "ind" => { "left" => "1134" } })
  2.times { blank.call }
  approver_block = { "ind" => { "left" => "567", "right" => "5103" }, "jc" => { "val" => "center" } }
  doc.append_paragraph([ "(", f("people.approver.display_name"), ")" ], **plain, ppr_set: approver_block)
  doc.append_paragraph([ f("people.approver.position_short") ], **plain, ppr_set: approver_block)

  2.times { blank.call }
  doc.append_paragraph([ f("org.unit_short"), " ", f("org.phone") ], **plain)
end

puts "wrote #{TARGET}"
