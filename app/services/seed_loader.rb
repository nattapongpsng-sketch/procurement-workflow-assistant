# Loads reference data, document templates and workflows from db/seeds.
# Safe to run repeatedly (upserts by natural key).
class SeedLoader
  ROOT = Rails.root.join("db/seeds")
  DOCX_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document".freeze

  def self.call(root: ROOT) = new(root).call

  def initialize(root)
    @root = Pathname(root)
  end

  def call
    load_recommended_ais
    load_people
    load_budget_sources
    load_document_templates
    Dir[@root.join("workflows/*.yml")].sort.map { |path| WorkflowLoader.load_file(path) }
  end

  private

  def yaml(relative) = YAML.safe_load_file(@root.join(relative), permitted_classes: [ Date ])

  def load_recommended_ais
    list = yaml("reference/recommended_ai.yml")
    list.fetch("items").each do |item|
      RecommendedAi.find_or_initialize_by(name: item.fetch("name"), list_version: list.fetch("list_version"))
                   .update!(item.slice("category", "capability", "vendor", "highlighted")
                                .merge("approved_on" => list["approved_on"], "active" => true))
    end
  end

  def load_people
    yaml("reference/people.yml").each do |person|
      Person.find_or_initialize_by(employee_code: person.fetch("employee_code").to_s).update!(person.except("employee_code"))
    end
  end

  def load_budget_sources
    yaml("reference/budget_sources.yml").each do |source|
      BudgetSource.find_or_initialize_by(ref_doc_no: source.fetch("ref_doc_no")).update!(source.except("ref_doc_no"))
    end
  end

  def load_document_templates
    yaml("documents.yml").each do |attrs|
      template = DocumentTemplate.find_or_initialize_by(code: attrs.fetch("code"), version: attrs.fetch("version"))
      template.assign_attributes(attrs.slice("name", "description", "template_path"))
      path = template.source_path or raise WorkflowLoader::Error, "ไม่พบไฟล์ template #{template.template_path}"
      checksum = Digest::SHA256.file(path).hexdigest
      if template.persisted? && template.checksum != checksum && template.generated_documents.exists?
        raise WorkflowLoader::Error, "#{template.code} v#{template.version} ถูกใช้สร้างเอกสารแล้ว แก้ไฟล์ต้องสร้างเวอร์ชันใหม่"
      end

      template.field_keys = DocxFields.paths(path)
      attach_needed = template.checksum != checksum || !template.docx_file.attached?
      template.checksum = checksum
      template.save!
      next unless attach_needed

      template.docx_file.attach(io: File.open(path), filename: path.basename.to_s,
                                content_type: DOCX_TYPE)
    end
  end
end
