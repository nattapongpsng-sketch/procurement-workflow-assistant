require "rails_helper"

RSpec.describe "Authentication" do
  it "sends visitors to the sign-in page" do
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it "signs in active users and signs them out" do
    user = create(:user)

    sign_in_as(user)
    expect(response).to redirect_to(root_url)
    follow_redirect!
    expect(response.body).to include(user.name)

    delete session_path
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "rejects wrong passwords and inactive users with a Thai message" do
    user = create(:user)

    post session_path, params: { email_address: user.email_address, password: "wrong-password-0000" }
    follow_redirect!
    expect(response.body).to include("อีเมลหรือรหัสผ่านไม่ถูกต้อง")

    user.update!(active: false)
    sign_in_as(user)
    follow_redirect!
    expect(response.body).to include("บัญชีนี้ถูกปิดใช้งาน")
  end
end
