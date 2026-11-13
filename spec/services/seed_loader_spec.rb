require "rails_helper"

RSpec.describe SeedLoader do
  it "loads the first workflow with every step, field and the full Recommended List" do
    described_class.call
    workflow = WorkflowTemplate.find_by!(code: "ai_purchase_under_50k", version: 1)

    expect(workflow).to be_published
    expect(workflow.workflow_steps.count).to eq(9)
    expect(workflow.workflow_steps.where(confirmed: false).pluck(:position)).to eq([ 6, 7, 8, 9 ])
    expect(workflow.document_templates.pluck(:code)).to eq([ "purchase_request" ])
    expect(RecommendedAi.count).to eq(23)
    expect(RecommendedAi.find_by!(name: "Claude").vendor).to eq("Anthropic PBC")
    expect(BudgetSource.find_by!(ref_doc_no: "กนว.(พน.)1182/2569").limit_amount).to eq(1_350_000)
  end

  it "is idempotent" do
    described_class.call

    expect { described_class.call }.not_to change {
      [ WorkflowTemplate.count, FieldDefinition.count, WorkflowStep.count, RecommendedAi.count, Person.count,
        ActiveStorage::Attachment.count ]
    }
  end

  it "records which template fields the docx uses" do
    described_class.call
    template = DocumentTemplate.find_by!(code: "purchase_request")

    expect(template.docx_file).to be_attached
    expect(template.field_keys).to include("request.subject", "budget.source.charge_text", "price.evidence")
  end

  it "maps every docx field to a workflow field" do
    workflow = described_class.call.first
    keys = workflow.field_definitions.map(&:key)
    reference_keys = workflow.field_definitions.select { |f| %w[reference person list].include?(f.field_type) }.map(&:key)

    unmapped = DocxFields.paths(DocumentTemplate.find_by!(code: "purchase_request").source_path).reject do |path|
      keys.include?(path) || reference_keys.any? { |key| path.start_with?("#{key}.") }
    end
    expect(unmapped).to be_empty
  end
end

RSpec.describe WorkflowLoader do
  let(:definition) do
    { "code" => "demo", "version" => 1, "status" => "published", "name" => "ตัวอย่าง",
      "field_groups" => [ { "key" => "g", "label" => "กลุ่ม" } ],
      "fields" => [ { "key" => "a.b", "group" => "g", "label" => "ก", "type" => "text", "help" => "h", "why" => "w" } ],
      "steps" => [ { "title" => "ขั้นที่ 1" } ] }
  end

  it "refuses to change a published version" do
    described_class.new(definition).call
    changed = definition.merge("name" => "ชื่อใหม่")

    expect { described_class.new(changed).call }.to raise_error(WorkflowLoader::Error, /เวอร์ชันใหม่/)
  end

  it "rejects formulas that reference undefined fields" do
    broken = definition.merge("fields" => definition["fields"] + [
      { "key" => "c", "group" => "g", "label" => "ค", "type" => "text", "computed" => { "fn" => "concat", "args" => [ "nope" ] } }
    ])

    expect { described_class.new(broken).call }.to raise_error(WorkflowLoader::Error, /nope/)
  end

  it "rejects fields in unknown groups" do
    broken = definition.merge("fields" => [ definition["fields"].first.merge("group" => "x") ])

    expect { described_class.new(broken).call }.to raise_error(WorkflowLoader::Error, /group x/)
  end
end
