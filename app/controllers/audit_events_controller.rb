# Read-only audit log for auditors and admins (Requirement FR-28, role ผู้ตรวจสอบ).
class AuditEventsController < ApplicationController
  require_role :auditor, :admin
  PER_PAGE = 50

  def index
    @filters = params.permit(:auditable_type, :action_name, :actor_id, :from, :to, :page)
    scope = AuditEvent.includes(:actor).recent
    scope = scope.where(auditable_type: @filters[:auditable_type]) if @filters[:auditable_type].present?
    scope = scope.where(action: @filters[:action_name]) if @filters[:action_name].present?
    scope = scope.where(actor_id: @filters[:actor_id]) if @filters[:actor_id].present?
    scope = scope.where(occurred_at: Date.parse(@filters[:from]).beginning_of_day..) if valid_date?(@filters[:from])
    scope = scope.where(occurred_at: ..Date.parse(@filters[:to]).end_of_day) if valid_date?(@filters[:to])
    @page = [ @filters[:page].to_i, 1 ].max
    @events = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @next_page = @events.size > PER_PAGE
    @events = @events.first(PER_PAGE)
    @types = AuditEvent.distinct.order(:auditable_type).pluck(:auditable_type)
  end

  private

  def valid_date?(value)
    value.present? && Date.iso8601(value)
  rescue Date::Error
    false
  end
end
