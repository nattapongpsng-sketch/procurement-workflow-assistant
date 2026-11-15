# Writes an AuditEvent for every create / update / destroy, in the same transaction as
# the change (if the audit row cannot be written, the change is rolled back).
#   class Person < ApplicationRecord
#     include Auditable
#     audit_ignore :some_noisy_column
#   end
module Auditable
  extend ActiveSupport::Concern

  ALWAYS_IGNORED = %w[created_at updated_at password_digest].freeze

  included do
    class_attribute :audit_ignored_attributes, default: ALWAYS_IGNORED
    after_create { audit!(:create, audited_changes) }
    after_update { (changes = audited_changes).any? && audit!(:update, changes) }
    after_destroy { audit!(:destroy, audited_attributes.transform_values { |value| [ value, nil ] }) }
  end

  class_methods do
    def audit_ignore(*attributes)
      self.audit_ignored_attributes = audit_ignored_attributes + attributes.map(&:to_s)
    end
  end

  def audit_events = AuditEvent.for_record(self).recent

  private

  def audit!(action, changes)
    AuditEvent.record(action:, auditable: self, changes:, summary: audit_summary)
  end

  def audited_changes = saved_changes.except(*audit_ignored_attributes)

  def audited_attributes = attributes.except(*audit_ignored_attributes)

  def audit_summary
    %i[title name label display_name code email_address].each do |method|
      value = try(method)
      return value.to_s.truncate(200) if value.present?
    end
    nil
  end
end
