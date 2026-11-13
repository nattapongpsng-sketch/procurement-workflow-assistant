FactoryBot.define do
  factory :recommended_ai do
    sequence(:name) { |n| "AI ทดสอบ #{n}" }
    category { "General AI Assistant" }
    vendor { "Example Inc." }
    list_version { "2569-04-08" }
  end

  # Fictional people only.
  factory :person do
    title_prefix { "นาย" }
    sequence(:full_name) { |n| "สมมติ ทดสอบ#{n}" }
    position_short { "วศก.5 (ฉ)" }
    unit_code { "สชก.(บก-ท)" }
    sequence(:employee_code) { |n| (900_000 + n).to_s }
  end

  factory :budget_source do
    sequence(:ref_doc_no) { |n| "กนว.(พน.)#{1000 + n}/2569" }
    ref_doc_date { Date.new(2026, 7, 13) }
    owner_unit { "กนว." }
    budget_type { "งบทำการ" }
    fiscal_year { 2569 }
    account_name { "ค่าใช้จ่ายในการวิจัย" }
    account_code { "53040010" }
    cost_center { "Z201022090" }
    limit_amount { 1_350_000 }
  end
end
