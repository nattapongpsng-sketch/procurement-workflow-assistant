require "rails_helper"

RSpec.describe WorkflowTemplate do
  it "requires a unique version per code" do
    create(:workflow_template, code: "ai", version: 1)
    duplicate = build(:workflow_template, code: "ai", version: 1)

    expect(duplicate).not_to be_valid
    expect(build(:workflow_template, code: "ai", version: 2)).to be_valid
  end

  it "rejects malformed eligibility rules with a reason" do
    template = build(:workflow_template, eligibility_rules: [ { "id" => "x", "title" => "x", "check" => { "nope" => 1 } } ])

    expect(template).not_to be_valid
    expect(template.errors[:eligibility_rules].join).to include("fail.reason", "nope")
  end

  it "freezes a published version" do
    template = create(:workflow_template, :published)

    expect(template.update(name: "ชื่อใหม่")).to be(false)
    expect(template.errors[:base].join).to include("เวอร์ชันใหม่")
    expect(template.reload.update(status: "archived")).to be(true)
  end

  it "finds the latest published version of each workflow" do
    old = create(:workflow_template, :published, code: "ai", version: 1)
    latest = create(:workflow_template, :published, code: "ai", version: 2)
    create(:workflow_template, code: "ai", version: 3)

    expect(described_class.latest_published).to contain_exactly(latest)
    expect(described_class.latest_published).not_to include(old)
  end
end
