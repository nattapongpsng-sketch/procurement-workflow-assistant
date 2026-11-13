require "rails_helper"

RSpec.describe "reference data" do
  describe Person do
    it "formats names and positions the way memos do" do
      person = build(:person, title_prefix: "นาย", full_name: "สมมติ ใจดี", position_short: "วศก.5 (ฉ)")

      expect(person.display_name).to eq("นายสมมติ ใจดี")
      expect(person.position_with_unit).to eq("วศก.5 (ฉ) สชก.(บก-ท)")
    end

    it "keeps employee codes unique" do
      create(:person, employee_code: "900001")

      expect(build(:person, employee_code: "900001")).not_to be_valid
    end
  end

  describe RecommendedAi do
    it "allows only active entries" do
      create(:recommended_ai, name: "Claude")
      create(:recommended_ai, name: "Old AI", active: false)

      expect(RecommendedAi.allowed?("Claude")).to be(true)
      expect(RecommendedAi.allowed?("Old AI")).to be(false)
    end
  end

  describe GeneratedDocument do
    it "numbers versions per case and template" do
      kase = create(:procurement_case)
      template = DocumentTemplate.new(code: "doc", version: 1, name: "เอกสาร", template_path: "x.docx")
      template.save!(validate: false)

      first = described_class.create!(procurement_case: kase, document_template: template)
      second = described_class.create!(procurement_case: kase, document_template: template)

      expect([ first.version, second.version ]).to eq([ 1, 2 ])
    end
  end
end
