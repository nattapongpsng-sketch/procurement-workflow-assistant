# Builds app/templates/docx/purchase_request.docx from the real form
# (docs/samples/ai-purchase/รายงานขอซื้อจ้าง claude .docx, kept out of git).
#
#   bundle exec ruby script/docx/prepare_purchase_request.rb [SOURCE.docx]
#
# Only the paragraphs listed in RULES are rebuilt: their text is kept and the
# matched parts are swapped for Sablon MERGEFIELDs, re-using the paragraph's
# original paragraph and run properties. Everything else in the file is left
# untouched (design principle 5). Patterns avoid real names on purpose.
require_relative "docx_template_builder"

SOURCE = ARGV[0] || File.expand_path("../../docs/samples/ai-purchase/รายงานขอซื้อจ้าง claude .docx", __dir__)
TARGET = File.expand_path("../../app/templates/docx/purchase_request.docx", __dir__)

PERSON = /น(?:างสาว|าย|าง)[^\s()]+ [^\s()]+/
POSITION = /[^\s()]+\.\d+ \(ฉ\) สชก\.\(บก-ท\)/

def f(expr) = DocxTemplateBuilder::Field.new(expr)

def person(key) = [ f("#{key}.display_name"), " ", f("#{key}.position_with_unit") ]

budget = "budget.source"

RULES = [
  # ── header table ──
  { match: /\AThai Skill Unit \(สชก\.\(บก-ท\)\)\z/, replace: [ [ /.+/, [ f("org.unit_name"), " (", f("org.unit_code"), ")" ] ] ] },
  { match: /\Aสชก\.\(บก-ท\)\z/, expect: 2, nth: [ 0 ], replace: [ [ /.+/, [ f("org.to") ] ] ] },
  { match: /\Aสชก\.\(บก-ท\)\z/, replace: [ [ /.+/, [ f("request.doc_number") ] ] ] },
  { match: /\Aรายงานขอซื้อขอจ้างจัดซื้อ/, replace: [ [ /.+/, [ f("request.subject") ] ] ] },
  { match: /\Aจำนวน 1 License\z/, delete: true },
  { match: /\Aผชก\.\(บก\.ท\)\z/, replace: [ [ /.+/, [ f("org.addressee") ] ] ] },
  { match: /\Aวันที่\s*\z/, cell_after: true, replace: [ [ /\A\z/, [ f("request.doc_date_text") ] ] ] },
  # ── body ──
  { match: /\Aด้วย Thai Skill มีความประสงค์/, replace: [
    [ /Thai Skill/, [ f("org.unit_short") ] ],
    [ /สิทธิการใช้งาน Software .+? จำนวน 1 License/, [ f("item.line") ] ]
  ] },
  { match: /\A\tตามอนุมัติ ผวก\. ลงวันที่ 12/, replace: [
    [ /\A\t.+?ในระยะนำร่องปี 2569(?= ต่อมา)/, [ "\t", f("justification.background") ] ],
    [ / ต่อมา .+\z/, [ " ต่อมา ", f("#{budget}.owner_unit"), " ได้แจ้ง", f("#{budget}.description"),
                       " ตามหนังสือ ", f("#{budget}.owner_unit"), " เลขที่ ", f("#{budget}.ref_doc_no"),
                       " ลงวันที่ ", f("#{budget}.ref_doc_date_text"), " จำนวน ", f("#{budget}.limit_basis"),
                       " ", f("#{budget}.limit_money"), " บาท (", f("#{budget}.limit_text"), ") โดยให้เบิกจ่ายจาก",
                       f("#{budget}.charge_text"), " (เอกสารแนบ 1)" ] ]
  ] },
  { match: /\A\tโดย Thai Skill มีความประสงค์/, replace: [
    [ /.+/, [ "\tโดย ", f("org.unit_short"), " มีความประสงค์ดำเนินการจัดซื้อ", f("item.line"), " (",
              f("justification.quantity_note"), ") ", f("justification.purpose") ] ]
  ] },
  { match: /\A\( Annual \) แบบรายปี/, delete: true },
  { match: /\A\tสิทธิการใช้งาน Software .+ License\z/, replace: [ [ /(?<=\A\t).+/, [ f("item.spec") ] ] ] },
  { match: /\A\tราคาที่ได้มาจากการสืบราคา/, replace: [
    [ /ราคาที่ได้มาจากการสืบราคาจากท้องตลาด/, [ f("price.reference_source") ] ],
    [ /[\d,]+\.- บาท \([^)]+\)/, [ f("price.reference_money"), " บาท (", f("price.reference_text"), ")" ] ],
    [ /\(รวมภาษีมูลค่าเพิ่ม\)/, [ "(รวมภาษีมูลค่าเพิ่ม)", f("price.usd_clause") ] ]
  ] },
  { match: /\A \tวงเงินไม่เกิน/, replace: [
    [ /[\d,]+\.- บาท \([^)]+\)/, [ f("budget.total_money"), " บาท (", f("budget.total_text"), ")" ] ],
    [ /(?<=โดยให้เบิกจ่ายจาก).+\z/, [ f("#{budget}.charge_text") ] ]
  ] },
  { match: /\A\t\s*\tวันที่ \d+ /, replace: [ [ /(?<=วันที่ ).+\z/, [ f("schedule.need_by_date_text") ] ] ] },
  { match: /\A\t\t8\.1 \tเห็นสมควรให้ /, replace: [ [ /#{PERSON} #{POSITION}/o, person("people.negotiator") ] ] },
  { match: /\A\t\t8\.2 \t/, replace: [ [ /#{PERSON} #{POSITION}/o, [ f("people.inspectors.text") ] ] ] },
  { match: /\A\t8\.3\t/, replace: [ [ /#{PERSON} #{POSITION}/o, person("people.borrower") ] ] },
  { match: /\Aจาก กกง\.\z/, replace: [ [ /กกง\./, [ f("loan.lender_unit") ] ] ] },
  # ── signature text boxes (each appears twice: DrawingML + VML fallback) ──
  { match: /\A\(#{PERSON}\)\z/o, expect: 4, nth: [ 0, 1 ], replace: [ [ /(?<=\().+(?=\))/, [ f("people.requester.display_name") ] ] ] },
  { match: /\AThai Skill BD Lead\z/, expect: 2, replace: [ [ /.+/, [ f("people.requester.position_en") ] ] ] },
  { match: /\A\(#{PERSON}\)\z/o, expect: 2, replace: [ [ /(?<=\().+(?=\))/, [ f("people.approver.display_name") ] ] ] },
  { match: /\AThai Skill BD Head\z/, expect: 2, replace: [ [ /.+/, [ f("people.approver.position_en") ] ] ] },
  # ── footer ──
  { match: /\AThai Skill Unit\/ สชก\.\(บก-ท\)\z/, replace: [ [ /.+/, [ f("org.unit_name"), "/ ", f("org.unit_code") ] ] ] },
  { match: /\Aโทร\. /, replace: [ [ /.+/, [ "โทร. ", f("org.phone"), " (", f("org.contact_label"), ")" ] ] ] }
].freeze

DocxTemplateBuilder.new(SOURCE, TARGET).build do |doc|
  RULES.each { |rule| doc.apply(rule) }
  doc.wrap_image(media: "word/media/image2.png", field: "price.evidence")
  doc.replace_media("word/media/image2.png", DocxTemplateBuilder.placeholder_png(716, 1490))
  doc.scrub_metadata!
end

puts "wrote #{TARGET}"
