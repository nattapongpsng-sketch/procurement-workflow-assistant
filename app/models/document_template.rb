# A real .docx form with MERGEFIELD placeholders (app/templates/docx).
# The .docx file is the source of truth for the document layout (design principle 5).
class DocumentTemplate < ApplicationRecord
  include Auditable

  TEMPLATE_DIR = Rails.root.join("app/templates/docx")

  has_one_attached :docx_file
  has_many :workflow_documents, dependent: :destroy
  has_many :generated_documents, dependent: :restrict_with_error

  validates :code, presence: true, format: { with: /\A[a-z][a-z0-9_]*\z/ }
  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 },
                      uniqueness: { scope: :code }
  validates :name, presence: true
  validates :template_path, presence: true, format: { with: /\A[a-z0-9_]+\.docx\z/, message: "ต้องเป็นชื่อไฟล์ .docx ใน app/templates/docx" }
  validate :template_file_exists

  # Resolved from the directory listing (never by joining user input into a path).
  def source_path
    TEMPLATE_DIR.children.find { |child| child.file? && child.basename.to_s == template_path }
  end

  private

  def template_file_exists
    return if template_path.blank? || errors.include?(:template_path)

    errors.add(:template_path, "ไม่พบไฟล์ #{template_path}") unless source_path
  end
end
