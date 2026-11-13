# A versioned procurement workflow defined as data (db/seeds/workflows/*.yml).
# A published version is frozen: changing a workflow means publishing a new version,
# and every case stays bound to the version it was created from.
class WorkflowTemplate < ApplicationRecord
  FROZEN_ATTRIBUTES = %w[code version name description keywords category procurement_method
                         legal_basis eligibility_rules field_groups summary source_digest].freeze

  enum :status, { draft: "draft", published: "published", archived: "archived" }, validate: true

  has_many :workflow_steps, -> { order(:position) }, dependent: :destroy, inverse_of: :workflow_template
  has_many :field_definitions, -> { order(:position) }, dependent: :destroy, inverse_of: :workflow_template
  has_many :workflow_documents, dependent: :destroy
  has_many :document_templates, through: :workflow_documents
  has_many :procurement_cases, dependent: :restrict_with_error

  validates :code, presence: true, format: { with: /\A[a-z][a-z0-9_]*\z/ }
  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 },
                      uniqueness: { scope: :code }
  validates :name, presence: true
  validate :keywords_and_legal_basis_are_string_lists
  validate :eligibility_rules_are_well_formed
  validate :published_version_is_frozen, on: :update

  scope :latest_published, -> {
    published.where(<<~SQL.squish)
      version = (SELECT MAX(w2.version) FROM workflow_templates w2
                 WHERE w2.code = workflow_templates.code AND w2.status = 'published')
    SQL
  }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def field(key)
    field_definitions.find { |definition| definition.key == key.to_s }
  end

  def to_param = "#{code}-v#{version}"

  private

  def keywords_and_legal_basis_are_string_lists
    { keywords:, legal_basis: }.each do |attribute, value|
      errors.add(attribute, "ต้องเป็นรายการข้อความ") unless value.is_a?(Array) && value.all?(String)
    end
  end

  def eligibility_rules_are_well_formed
    unless eligibility_rules.is_a?(Array)
      errors.add(:eligibility_rules, "ต้องเป็นรายการ")
      return
    end

    eligibility_rules.each_with_index do |rule, index|
      problems = EligibilityEvaluator.rule_problems(rule)
      problems.each { |problem| errors.add(:eligibility_rules, "ข้อที่ #{index + 1}: #{problem}") }
    end
  end

  def published_version_is_frozen
    return unless status_in_database == "published"

    changed_frozen = changed & FROZEN_ATTRIBUTES
    return if changed_frozen.empty?

    errors.add(:base, "เวอร์ชันที่เผยแพร่แล้วแก้ไขไม่ได้ ให้สร้างเวอร์ชันใหม่ (แก้: #{changed_frozen.join(', ')})")
  end
end
