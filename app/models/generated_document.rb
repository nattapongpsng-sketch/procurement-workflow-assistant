# One rendered .docx for a case. Keeps the exact data it was rendered from.
class GeneratedDocument < ApplicationRecord
  enum :status, { pending: "pending", generating: "generating", succeeded: "succeeded", failed: "failed" },
       validate: true

  belongs_to :procurement_case
  belongs_to :document_template
  has_one_attached :file

  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 },
                      uniqueness: { scope: [ :procurement_case_id, :document_template_id ] }

  before_validation :assign_next_version, on: :create

  def filename
    "#{document_template.code}-case#{procurement_case_id}-v#{version}.docx"
  end

  private

  def assign_next_version
    return if version.present? || procurement_case.nil? || document_template.nil?

    latest = self.class.where(procurement_case:, document_template:).maximum(:version) || 0
    self.version = latest + 1
  end
end
