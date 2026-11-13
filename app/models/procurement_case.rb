# A procurement matter ("เรื่อง") created from a workflow template version.
# `data` holds every field value flat by FieldDefinition#key, entered once and
# reused by every document (design principle 2).
class ProcurementCase < ApplicationRecord
  enum :status, { draft: "draft", submitted: "submitted", approved: "approved", closed: "closed",
                  cancelled: "cancelled" }, validate: true

  belongs_to :workflow_template
  has_many :generated_documents, dependent: :destroy
  # Evidence files (e.g. price screenshot). File fields store the blob's signed id.
  has_many_attached :attachments

  validates :title, presence: true
  validate :data_is_a_hash
  validate :data_keys_are_defined
  validate :computed_values_are_not_stored

  def value(key) = data[key.to_s]

  def assign_values(values)
    self.data = data.merge(values.to_h.stringify_keys)
  end

  def missing_required_keys
    workflow_template.field_definitions.select { |f| f.input? && f.required && value(f.key).blank? }.map(&:key)
  end

  private

  def data_is_a_hash
    errors.add(:data, "ต้องเป็น object") unless data.is_a?(Hash)
  end

  def data_keys_are_defined
    return unless data.is_a?(Hash) && workflow_template

    unknown = data.keys - workflow_template.field_definitions.map(&:key)
    errors.add(:data, "มีฟิลด์ที่ไม่ได้นิยามใน workflow: #{unknown.join(', ')}") if unknown.any?
  end

  # Design principle 3: computed values are derived, never typed in.
  def computed_values_are_not_stored
    return unless data.is_a?(Hash) && workflow_template

    stored = workflow_template.field_definitions.select(&:computed?).map(&:key) & data.keys
    errors.add(:data, "ห้ามกรอกค่าที่ระบบคำนวณเอง: #{stored.join(', ')}") if stored.any?
  end
end
