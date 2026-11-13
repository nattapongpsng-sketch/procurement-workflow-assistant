# One input (or computed value) collected at the case level and shared by every document.
class FieldDefinition < ApplicationRecord
  TYPES = %w[text longtext number money date boolean person select list file reference].freeze
  KEY_FORMAT = /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*\z/

  belongs_to :workflow_template, inverse_of: :field_definitions

  validates :key, presence: true, format: { with: KEY_FORMAT }, uniqueness: { scope: :workflow_template_id }
  validates :label, :group_key, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  validates :field_type, inclusion: { in: TYPES }
  validate :input_fields_explain_themselves
  validate :computed_formula_is_known
  validate :select_has_choices

  def computed? = computed.present?

  def input? = !computed?

  private

  # Design principle 6: every field the user fills in has help text and a reason.
  def input_fields_explain_themselves
    return if computed?

    errors.add(:help, "ต้องมีคำอธิบาย") if help.blank?
    errors.add(:why, "ต้องบอกเหตุผลว่าทำไมต้องกรอก") if why.blank?
  end

  def computed_formula_is_known
    return unless computed?

    FieldComputer.formula_problems(computed).each { |problem| errors.add(:computed, problem) }
  end

  def select_has_choices
    return unless field_type == "select"

    choices = options["choices"]
    errors.add(:options, "ต้องมี choices") unless choices.is_a?(Array) && choices.any?
  end
end
