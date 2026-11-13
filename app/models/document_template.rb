# A real .docx form with MERGEFIELD placeholders (app/templates/docx).
# The .docx file is the source of truth for the document layout (design principle 5).
class DocumentTemplate < ApplicationRecord
  TEMPLATE_DIR = Rails.root.join("app/templates/docx")

  has_one_attached :docx_file
  has_many :workflow_documents, dependent: :destroy
  has_many :generated_documents, dependent: :restrict_with_error

  validates :code, presence: true, format: { with: /\A[a-z][a-z0-9_]*\z/ }
  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 },
                      uniqueness: { scope: :code }
  validates :name, :template_path, presence: true
  validate :template_file_exists

  def source_path = TEMPLATE_DIR.join(template_path)

  private

  def template_file_exists
    return if template_path.blank?

    errors.add(:template_path, "ไม่พบไฟล์ #{template_path}") unless File.file?(source_path)
  end
end
