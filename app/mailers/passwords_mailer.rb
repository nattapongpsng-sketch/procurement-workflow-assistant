class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "ตั้งรหัสผ่านใหม่ — จัดซื้อง่าย", to: user.email_address
  end
end
