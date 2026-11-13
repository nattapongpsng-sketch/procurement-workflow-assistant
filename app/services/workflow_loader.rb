# Loads a workflow definition (db/seeds/workflows/*.yml) into the database.
# Idempotent: an unchanged published version is skipped; a changed published
# version is refused so cases keep the exact workflow they were created with.
class WorkflowLoader
  class Error < StandardError; end

  def self.load_file(path)
    new(YAML.safe_load_file(path), source: path.to_s).call
  end

  def initialize(definition, source: "inline")
    @definition = definition.deep_stringify_keys
    @source = source
  end

  def call
    check_definition!
    template = WorkflowTemplate.find_or_initialize_by(code: @definition.fetch("code"), version: @definition.fetch("version"))
    return template if template.published? && template.source_digest == digest

    if template.published? || template.archived?
      raise Error, "#{template.code} v#{template.version} เผยแพร่แล้วแต่ไฟล์ #{@source} เปลี่ยน ให้สร้างเวอร์ชันใหม่"
    end

    WorkflowTemplate.transaction do
      template.update!(attributes)
      replace_children(template)
      template.publish! if @definition["status"] == "published"
    end
    template
  end

  private

  def digest = @digest ||= Digest::SHA256.hexdigest(JSON.generate(@definition))

  def attributes
    {
      name: @definition.fetch("name"), description: @definition["description"],
      keywords: Array(@definition["keywords"]).map(&:to_s), category: @definition["category"],
      procurement_method: @definition["procurement_method"], legal_basis: Array(@definition["legal_basis"]),
      eligibility_rules: Array(@definition["eligibility_rules"]), field_groups: Array(@definition["field_groups"]),
      summary: @definition["summary"] || {}, source_digest: digest, status: "draft"
    }
  end

  def replace_children(template)
    template.workflow_steps.destroy_all
    template.field_definitions.destroy_all
    template.workflow_documents.destroy_all

    fields.each_with_index do |field, index|
      template.field_definitions.create!(
        key: field.fetch("key"), label: field.fetch("label"), group_key: field.fetch("group"),
        position: index + 1, field_type: field.fetch("type"), required: field.fetch("required", false),
        help: field["help"], example: field["example"]&.to_s, why: field["why"],
        validation: field["validation"] || {}, computed: field["computed"], options: field["options"] || {}
      )
    end

    Array(@definition["steps"]).each_with_index do |step, index|
      template.workflow_steps.create!(
        position: index + 1, title: step.fetch("title"), description: step["description"],
        actor_role: step["actor_role"], output_documents: Array(step["output_documents"]),
        required_attachments: Array(step["required_attachments"]), tips: step["tips"],
        estimated_duration: step["estimated_duration"], confirmed: step.fetch("confirmed", true)
      )
    end

    Array(@definition["documents"]).each do |document|
      document_template = DocumentTemplate.where(code: document.fetch("code")).order(:version).last
      raise Error, "ไม่พบ document template #{document['code']} (โหลด db/seeds/documents.yml ก่อน)" unless document_template

      template.workflow_documents.create!(document_template:, step_position: document["step"])
    end
  end

  def fields = Array(@definition["fields"])

  def check_definition!
    keys = fields.map { |field| field["key"] }
    duplicates = keys.tally.select { |_, count| count > 1 }.keys
    problems = []
    problems << "key ซ้ำ: #{duplicates.join(', ')}" if duplicates.any?

    groups = Array(@definition["field_groups"]).map { |group| group["key"] }
    fields.each do |field|
      problems << "#{field['key']}: ไม่มี group #{field['group']}" unless groups.include?(field["group"])
      Array(field.dig("computed", "args")).grep(String).each do |arg|
        problems << "#{field['key']}: สูตรอ้าง #{arg} ที่ไม่ได้นิยาม" unless keys.include?(arg)
      end
    end
    raise Error, "#{@source}: #{problems.join('; ')}" if problems.any?
  end
end
