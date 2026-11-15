require "rails_helper"

RSpec.describe User do
  it "accepts several known roles and rejects unknown ones" do
    expect(build(:user, roles: %w[requester inspector])).to be_valid
    user = build(:user, roles: %w[requester superuser])

    expect(user).not_to be_valid
    expect(user.errors[:roles].join).to include("superuser")
  end

  it "requires a department unless the user sees the whole organization" do
    expect(build(:user, roles: [ "requester" ], department: nil)).not_to be_valid
    expect(build(:user, roles: [ "auditor" ], department: nil)).to be_valid
    expect(build(:user, :admin)).to be_valid
  end

  it "requires passwords of at least 12 characters" do
    expect(build(:user, password: "short")).not_to be_valid
  end

  it "normalizes email and roles" do
    user = create(:user, email_address: " Someone@Example.COM ", roles: [ "requester", "", "requester" ])

    expect(user.email_address).to eq("someone@example.com")
    expect(user.roles).to eq([ "requester" ])
  end

  it "finds users by role and labels roles in Thai" do
    inspector = create(:user, roles: %w[requester inspector])
    create(:user, roles: [ "finance" ])

    expect(described_class.with_role(:inspector)).to contain_exactly(inspector)
    expect(inspector.role_labels).to eq([ "ผู้ขอซื้อ / ขอเบิก", "ผู้ตรวจรับพัสดุ" ])
  end
end
