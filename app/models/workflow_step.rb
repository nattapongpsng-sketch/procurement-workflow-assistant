class WorkflowStep < ApplicationRecord
  include Auditable

  ACTOR_ROLES = %w[requester approver inspector borrower finance organization].freeze

  belongs_to :workflow_template, inverse_of: :workflow_steps

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :workflow_template_id }
  validates :title, presence: true
  validates :actor_role, inclusion: { in: ACTOR_ROLES }, allow_nil: true

  def actor_label = I18n.t("roles.#{actor_role}", default: actor_role)
end
