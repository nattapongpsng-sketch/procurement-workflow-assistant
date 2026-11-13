require "rails_helper"

RSpec.describe EligibilityEvaluator do
  let!(:claude) { create(:recommended_ai, name: "Claude") }
  let(:rules) do
    [
      { "id" => "in_list", "title" => "อยู่ใน Recommended List",
        "check" => { "in_reference" => { "field" => "item.ai_product", "table" => "recommended_ai" } },
        "fail" => { "reason" => "ไม่อยู่ใน Recommended List", "alternatives" => [ "ai_not_in_list" ] } },
      { "id" => "max_50k", "title" => "ไม่เกิน 50,000 บาท",
        "check" => { "lte" => [ "budget.total", 50_000 ] },
        "fail" => { "reason" => "เกิน 50,000 บาท", "alternatives" => [ "ai_over_50k" ] } }
    ]
  end
  let(:template) { create(:workflow_template, eligibility_rules: rules) }

  before do
    create(:field_definition, workflow_template: template, key: "item.ai_product", field_type: "reference")
    create(:field_definition, workflow_template: template, key: "budget.total", field_type: "money")
  end

  def evaluate(data) = described_class.new(template, data).call

  it "passes when every rule is met" do
    outcome = evaluate("item.ai_product" => claude.id, "budget.total" => "7990")

    expect(outcome).to be_eligible
  end

  it "explains failures and suggests alternatives" do
    outcome = evaluate("item.ai_product" => claude.id + 999, "budget.total" => "60000")

    expect(outcome).not_to be_eligible
    expect(outcome.failures.map(&:message)).to eq([ "ไม่อยู่ใน Recommended List", "เกิน 50,000 บาท" ])
    expect(outcome.alternatives).to eq(%w[ai_not_in_list ai_over_50k])
  end

  it "reports rules it cannot check yet as unknown" do
    outcome = evaluate("item.ai_product" => claude.id)

    expect(outcome.unknowns.map(&:rule_id)).to eq([ "max_50k" ])
    expect(outcome).not_to be_eligible
  end

  it "treats the boundary as eligible" do
    expect(evaluate("item.ai_product" => claude.id, "budget.total" => "50000")).to be_eligible
    expect(evaluate("item.ai_product" => claude.id, "budget.total" => "50000.01")).not_to be_eligible
  end

  it "supports all/any" do
    problems = described_class.check_problems("any" => [ { "present" => "a" }, { "gte" => [ "b", 1 ] } ])

    expect(problems).to be_empty
  end
end
