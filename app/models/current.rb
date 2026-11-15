class Current < ActiveSupport::CurrentAttributes
  attribute :session, :request_ip, :user_agent, :request_id
  delegate :user, to: :session, allow_nil: true

  # Stored with every audit event.
  def request_metadata
    { "ip" => request_ip, "user_agent" => user_agent, "request_id" => request_id }.compact
  end
end
