require "rails_helper"

RSpec.describe WorkflowSearch do
  let!(:ai) do
    create(:workflow_template, :published, code: "ai", name: "จัดซื้อโปรแกรม AI วงเงินไม่เกิน 50,000 บาท",
                                           keywords: %w[AI Claude license ซอฟต์แวร์], description: "วิธีเฉพาะเจาะจง")
  end
  let!(:service) do
    create(:workflow_template, :published, code: "service", name: "จ้างเหมาบริการทำความสะอาด", keywords: %w[จ้างเหมา บริการ])
  end

  def codes(query) = described_class.call(query).map { |r| r.workflow.code }

  it "matches Thai and English words" do
    expect(codes("ซื้อ AI")).to eq([ "ai" ])
    expect(codes("license ซอฟต์แวร์")).to eq([ "ai" ])
    expect(codes("จ้างเหมาบริการ")).to eq([ "service" ])
  end

  it "matches keywords inside an unspaced Thai query" do
    expect(codes("อยากซื้อclaudeให้ทีม")).to eq([ "ai" ])
  end

  it "is case-insensitive and reports matched keywords" do
    result = described_class.call("CLAUDE").first

    expect(result.matched_terms).to eq([ "Claude" ])
  end

  it "returns nothing for unrelated queries and everything for a blank query" do
    expect(codes("รถยนต์")).to be_empty
    expect(codes("  ")).to contain_exactly("ai", "service")
  end

  it "only searches the latest published version" do
    create(:workflow_template, :published, code: "ai", version: 2, name: "จัดซื้อโปรแกรม AI (ปรับปรุง)", keywords: %w[AI])
    create(:workflow_template, code: "draft", name: "ร่าง AI", keywords: %w[AI])

    expect(described_class.call("AI").map { |r| [ r.workflow.code, r.workflow.version ] }).to eq([ [ "ai", 2 ] ])
  end
end
