# Turns a case into the nested hash a .docx template reads:
#   "budget.source" (id) => { "budget" => { "source" => { "ref_doc_no" => ..., "charge_text" => ... } } }
# All formatting (Thai dates, money, amounts in words) happens here or in
# FieldComputer, never in the template (design principle 3).
class DocumentContext
  EVIDENCE_BOX_CM = { max_w: 12.6, max_h: 24.0 }.freeze

  def self.build(procurement_case, for_snapshot: false) = new(procurement_case).build(for_snapshot:)

  def initialize(procurement_case)
    @case = procurement_case
    @template = procurement_case.workflow_template
  end

  def build(for_snapshot: false)
    values = FieldComputer.new(@template, @case.data).values
    @template.field_definitions.each_with_object({}) do |definition, context|
      value = present(definition, values[definition.key], for_snapshot:)
      nest(context, definition.key, value)
    end
  end

  private

  def present(definition, value, for_snapshot:)
    return nil if value.blank?

    case definition.field_type
    when "reference" then present_reference(definition.options["table"], value)
    when "person" then person(Person.find_by(id: value))
    when "list" then definition.options["of"] == "person" ? people(value) : Array(value)
    when "file" then for_snapshot ? file_snapshot(value) : image(value)
    when "date" then Thai.date(value)
    when "money", "number" then FieldComputer.text(value)
    else value
    end
  end

  def present_reference(table, id)
    record = ReferenceTables.find(table, id)
    case record
    when BudgetSource then budget_source(record)
    when Person then person(record)
    when RecommendedAi then record.slice("name", "vendor", "category").merge("label" => "#{record.name} (#{record.vendor})")
    end
  end

  def person(record)
    return nil unless record

    {
      "display_name" => record.display_name, "position_short" => record.position_short,
      "position_with_unit" => record.position_with_unit, "position_en" => record.position_en,
      "employee_code" => record.employee_code, "unit_code" => record.unit_code,
      "name_and_position" => "#{record.display_name} #{record.position_with_unit}"
    }
  end

  def people(ids)
    records = Person.where(id: Array(ids)).index_by(&:id)
    items = Array(ids).filter_map { |id| person(records[id.to_i]) }
    { "items" => items, "text" => items.map { |item| item["name_and_position"] }.join(" และ ") }
  end

  def budget_source(source)
    charge = "#{source.budget_type}ปี #{source.fiscal_year} ของ #{source.owner_unit} บัญชี#{source.account_name} " \
             "รหัสบัญชี #{source.account_code} ศูนย์ต้นทุน #{source.cost_center}"
    {
      "ref_doc_no" => source.ref_doc_no, "ref_doc_date_text" => Thai.date(source.ref_doc_date),
      "owner_unit" => source.owner_unit, "description" => source.description, "budget_type" => source.budget_type,
      "fiscal_year" => source.fiscal_year.to_s, "account_name" => source.account_name,
      "account_code" => source.account_code, "cost_center" => source.cost_center,
      "limit_basis" => source.limit_basis, "limit_money" => source.limit_amount && Thai.money(source.limit_amount),
      "limit_text" => source.limit_amount && Thai.baht_text(source.limit_amount), "charge_text" => charge
    }
  end

  def blob(signed_id) = ActiveStorage::Blob.find_signed(signed_id)

  def image(signed_id)
    blob = blob(signed_id) or return nil
    bytes = blob.download
    properties = ImageDimensions.fit_cm(bytes, **EVIDENCE_BOX_CM) || {}
    Sablon.content(:image, StringIO.new(bytes), filename: blob.filename.to_s, properties:)
  end

  def file_snapshot(signed_id)
    blob = blob(signed_id) or return nil
    { "filename" => blob.filename.to_s, "checksum" => blob.checksum, "blob_id" => blob.id }
  end

  def nest(context, key, value)
    *parents, leaf = key.split(".")
    node = parents.inject(context) do |current, part|
      current[part] = {} unless current[part].is_a?(Hash)
      current[part]
    end
    node[leaf] = value
  end
end
