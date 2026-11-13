# A case that mirrors the content of the real purchase request form
# (docs/samples, ยอด 7,990 ตาม template — ดู OPEN_QUESTIONS Q1) with fictional
# people from db/seeds/reference/people.yml.
module PurchaseRequestFixture
  PURPOSE = "เพื่อนำมาใช้เป็นเครื่องมือช่วยลดภาระงานเอกสารของบุคลากรในกระบวนการต่าง ๆ " \
            "ที่ต้องดำเนินการต่อเนื่องภายหลังจากลูกค้าขึ้นทะเบียนเข้าสู่ระบบ อาทิ การจัดใบรับรองการมีส่วนร่วมของผู้เข้าร่วมงาน " \
            "การขึ้นทะเบียน carbon neutral event ตลอดจนการประมวลผลและสรุปข้อมูลที่เกี่ยวข้อง " \
            "นอกจากนี้ยังใช้สนับสนุนงานวิเคราะห์แผนธุรกิจเพื่อประกอบการตัดสินใจเชิงกลยุทธ์ " \
            "และใช้เป็นเครื่องมือช่วยในการพัฒนาซอฟต์แวร์ของทีม ทั้งนี้เพื่อ ลดระยะเวลาการทำงานที่ต้องทำซ้ำซ้อน " \
            "และเพิ่มประสิทธิภาพการทำงานร่วมกันของบุคลากรโดยรวม".freeze
  BACKGROUND = "ตามอนุมัติ ผวก. ลงวันที่ 12 มิถุนายน 2569 (หนังสือ กธน. เลขที่ กธน.(วน) 496/2569 ลงวันที่ 20 พฤษภาคม 2569) " \
               "อนุมัติเปลี่ยนแปลงหน่วยงานดำเนินธุรกิจ โดยอนุมัติให้หน่วยธุรกิจ Thai Skill (สชก.(บก-ท)) " \
               "ดำเนินการขยายผลนวัตกรรมธุรกิจ carbonMICE เชิงพาณิชย์ในระยะนำร่องปี 2569".freeze
  EVIDENCE = Rails.root.join("spec/fixtures/files/price_evidence.png")

  def build_purchase_request_case(overrides = {})
    SeedLoader.call
    workflow = WorkflowTemplate.find_by!(code: "ai_purchase_under_50k", version: 1)
    people = Person.all.index_by(&:employee_code)
    evidence = ActiveStorage::Blob.create_and_upload!(io: File.open(EVIDENCE), filename: "price_evidence.png",
                                                      content_type: "image/png")
    data = {
      "org.unit_name" => "Thai Skill Unit", "org.unit_short" => "Thai Skill", "org.unit_code" => "สชก.(บก-ท)",
      "org.to" => "สชก.(บก-ท)", "org.addressee" => "ผชก.(บก.ท)", "org.phone" => "6682", "org.contact_label" => "สมชาย",
      "item.ai_product" => RecommendedAi.find_by!(name: "Claude").id,
      "item.name" => "สิทธิการใช้งาน Software Claude Pro (Annual) แบบรายปี", "item.quantity" => "1", "item.unit" => "License",
      "justification.background" => BACKGROUND, "justification.purpose" => PURPOSE,
      "schedule.need_by_date" => "2026-09-15",
      "price.currency" => "THB", "price.thb_amount" => "7990", "price.source_url" => "https://claude.com/pricing",
      "price.survey_date" => "2026-07-17", "price.evidence" => evidence.signed_id,
      "budget.source" => BudgetSource.find_by!(ref_doc_no: "กนว.(พน.)1182/2569").id,
      "people.requester" => people.fetch("900003").id, "people.negotiator" => people.fetch("900001").id,
      "people.inspectors" => [ people.fetch("900002").id ], "people.borrower" => people.fetch("900001").id,
      "people.approver" => people.fetch("900004").id
    }.merge(overrides)
    ProcurementCase.create!(workflow_template: workflow, title: "จัดซื้อสิทธิการใช้งาน Claude Pro (Annual) 1 License",
                            data: data.compact)
  end
end

RSpec.configure { |config| config.include PurchaseRequestFixture }
