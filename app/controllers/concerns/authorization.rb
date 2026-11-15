# Role checks for controllers (Requirement "ผู้ใช้และบทบาท", NFR-05).
#   require_role :admin
#   require_role :procurement_officer, :procurement_head, only: :update
module Authorization
  extend ActiveSupport::Concern

  class NotAuthorized < StandardError; end

  included do
    rescue_from NotAuthorized, with: :deny_access
  end

  class_methods do
    def require_role(*roles, **options)
      before_action(**options) { authorize_roles!(*roles) }
    end
  end

  private

  def authorize_roles!(*roles)
    raise NotAuthorized unless Current.user && roles.any? { |role| Current.user.role?(role) }
  end

  def deny_access
    redirect_to root_path, alert: "คุณไม่มีสิทธิ์ใช้หน้านี้ ถ้าคิดว่าควรมี กรุณาติดต่อผู้ดูแลระบบ", status: :see_other
  end
end
