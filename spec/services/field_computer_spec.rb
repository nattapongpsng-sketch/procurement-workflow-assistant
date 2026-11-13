require "rails_helper"

RSpec.describe FieldComputer do
  let(:template) { create(:workflow_template) }

  def field(key, type = "text", computed: nil)
    attrs = { workflow_template: template, key:, field_type: type }
    computed ? create(:field_definition, :computed, **attrs, computed:) : create(:field_definition, **attrs)
  end

  before do
    field("org.unit_code")
    field("request.doc_no")
    field("request.doc_date", "date")
    field("price.foreign_amount", "money")
    field("price.exchange_rate", "number")
    field("item.quantity", "number")
    field("price.unit_price", "money", computed: { "fn" => "multiply", "args" => %w[price.foreign_amount price.exchange_rate] })
    field("budget.total", "money", computed: { "fn" => "multiply", "args" => %w[price.unit_price item.quantity] })
    field("budget.total_text", computed: { "fn" => "baht_text", "args" => [ "budget.total" ] })
    field("budget.total_money", computed: { "fn" => "money", "args" => [ "budget.total" ] })
    field("request.doc_date_text", computed: { "fn" => "thai_date", "args" => [ "request.doc_date" ] })
    field("fiscal_year", "number", computed: { "fn" => "buddhist_year", "args" => [ "request.doc_date" ] })
    field("request.doc_number", computed: { "fn" => "doc_number", "args" => %w[org.unit_code request.doc_no fiscal_year] })
  end

  let(:data) do
    { "org.unit_code" => "สชก.(บก-ท)", "request.doc_date" => "2026-07-17",
      "price.foreign_amount" => "200", "price.exchange_rate" => "34", "item.quantity" => "1" }
  end

  it "derives chained values: USD × rate, total, words, Thai date, doc number" do
    values = described_class.new(template, data).values

    expect(values["price.unit_price"]).to eq(6800)
    expect(values["budget.total_text"]).to eq("หกพันแปดร้อยบาทถ้วน")
    expect(values["budget.total_money"]).to eq("6,800.-")
    expect(values["request.doc_date_text"]).to eq("17 กรกฎาคม 2569")
    expect(values["request.doc_number"]).to eq("สชก.(บก-ท)         /2569")
  end

  it "leaves computed values empty when inputs are missing" do
    values = described_class.new(template, data.except("price.exchange_rate")).values

    expect(values["budget.total"]).to be_nil
    expect(values["budget.total_text"]).to be_nil
  end

  it "detects formula cycles" do
    field("loop.a", computed: { "fn" => "concat", "args" => [ "loop.b" ] })
    field("loop.b", computed: { "fn" => "concat", "args" => [ "loop.a" ] })

    expect { described_class.new(template.reload, {}).value("loop.a") }.to raise_error(FieldComputer::CycleError)
  end
end
