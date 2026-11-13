FactoryBot.define do
  factory :workflow_template do
    sequence(:code) { |n| "workflow_#{n}" }
    version { 1 }
    name { "จัดซื้อทดสอบ" }
    keywords { [ "ทดสอบ" ] }
    legal_basis { [] }
    eligibility_rules { [] }

    trait :published do
      status { "published" }
      published_at { Time.current }
    end
  end

  factory :workflow_step do
    workflow_template
    sequence(:position)
    title { "ขั้นตอนทดสอบ" }
    actor_role { "requester" }
  end

  factory :field_definition do
    workflow_template
    sequence(:key) { |n| "group.field_#{n}" }
    label { "ฟิลด์ทดสอบ" }
    group_key { "group" }
    sequence(:position)
    field_type { "text" }
    help { "คำอธิบาย" }
    why { "เหตุผล" }

    trait :computed do
      help { nil }
      why { nil }
      computed { { "fn" => "multiply", "args" => [ "a", "b" ] } }
    end
  end

  factory :document_template do
    sequence(:code) { |n| "doc_#{n}" }
    version { 1 }
    name { "เอกสารทดสอบ" }
    template_path { "purchase_request.docx" }
  end

  factory :procurement_case do
    workflow_template
    title { "เรื่องทดสอบ" }
  end
end
