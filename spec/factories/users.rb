FactoryBot.define do
  factory :organization do
    sequence(:code) { |n| "ORG#{n}" }
    name { "หน่วยงานทดสอบ" }
  end

  factory :department do
    organization
    sequence(:code) { |n| "DEP#{n}" }
    name { "ส่วนงานทดสอบ" }
  end

  factory :position do
    organization
    sequence(:title) { |n| "ตำแหน่ง #{n}" }
  end

  # Fictional people only.
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    name { "ผู้ใช้ ทดสอบ" }
    password { "test-password-1234" }
    roles { [ "requester" ] }
    department

    trait :admin do
      roles { [ "admin" ] }
      department { nil }
    end
  end
end
