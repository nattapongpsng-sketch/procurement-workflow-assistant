require "rails_helper"

RSpec.describe FieldDefinition do
  it "requires help and a reason for input fields" do
    field = build(:field_definition, help: nil, why: "")

    expect(field).not_to be_valid
    expect(field.errors.attribute_names).to include(:help, :why)
  end

  it "does not require help for computed fields" do
    expect(build(:field_definition, :computed)).to be_valid
  end

  it "rejects unknown formulas" do
    field = build(:field_definition, :computed, computed: { "fn" => "eval", "args" => [] })

    expect(field).not_to be_valid
    expect(field.errors[:computed].join).to include("eval")
  end

  it "validates key format and type" do
    expect(build(:field_definition, key: "Bad Key")).not_to be_valid
    expect(build(:field_definition, field_type: "html")).not_to be_valid
  end

  it "requires choices for select fields" do
    expect(build(:field_definition, field_type: "select")).not_to be_valid
    expect(build(:field_definition, field_type: "select", options: { "choices" => [ "ก" ] })).to be_valid
  end
end
