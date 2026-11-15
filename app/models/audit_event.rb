# Append-only audit log (Requirement FR-28). Rows are written by Auditable callbacks
# or AuditEvent.record for domain actions (approve, return, cancel...). PostgreSQL
# triggers reject every UPDATE / DELETE / TRUNCATE; the model is read-only once saved.
class AuditEvent < ApplicationRecord
  ACTIONS = %w[create update destroy sign_in sign_out approve reject return cancel generate export].freeze

  belongs_to :actor, class_name: "User", optional: true

  validates :action, inclusion: { in: ACTIONS }
  validates :auditable_type, :auditable_id, :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc, id: :desc) }
  scope :for_record, ->(record) { where(auditable_type: record.class.base_class.name, auditable_id: record.id) }

  def self.record(action:, auditable:, changes: {}, summary: nil, actor: Current.user)
    create!(action: action.to_s, auditable_type: auditable.class.base_class.name, auditable_id: auditable.id,
            summary:, changes_data: changes, actor:, occurred_at: Time.current, metadata: Current.request_metadata)
  end

  def readonly? = persisted?

  def action_label = I18n.t("audit_actions.#{action}", default: action)

  def auditable_label = auditable_type.safe_constantize&.model_name&.human || auditable_type
end
