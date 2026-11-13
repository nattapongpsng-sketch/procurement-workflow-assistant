require "rails_helper"

RSpec.describe ProcurementCase do
  let(:template) { create(:workflow_template) }

  before do
    create(:field_definition, workflow_template: template, key: "price.unit_price", field_type: "money", required: true)
    create(:field_definition, workflow_template: template, key: "item.quantity", field_type: "number")
    create(:field_definition, :computed, workflow_template: template, key: "budget.total",
                                         computed: { "fn" => "multiply", "args" => %w[price.unit_price item.quantity] })
  end

  it "accepts values for defined input fields" do
    kase = build(:procurement_case, workflow_template: template, data: { "price.unit_price" => "7990" })

    expect(kase).to be_valid
  end

  it "rejects keys the workflow does not define" do
    kase = build(:procurement_case, workflow_template: template, data: { "unknown.key" => "x" })

    expect(kase).not_to be_valid
  end

  it "rejects typed-in computed values" do
    kase = build(:procurement_case, workflow_template: template, data: { "budget.total" => "1" })

    expect(kase).not_to be_valid
    expect(kase.errors[:data].join).to include("budget.total")
  end

  it "lists missing required inputs" do
    kase = build(:procurement_case, workflow_template: template)

    expect(kase.missing_required_keys).to eq([ "price.unit_price" ])
  end
end
