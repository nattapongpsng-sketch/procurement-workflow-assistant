module SignInHelpers
  PASSWORD = "test-password-1234".freeze

  # Request specs
  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: PASSWORD }
  end
end

module SystemSignInHelpers
  def sign_in_as(user)
    visit new_session_path
    fill_in "อีเมล", with: user.email_address
    fill_in "รหัสผ่าน", with: SignInHelpers::PASSWORD
    click_button "เข้าสู่ระบบ"
  end
end

RSpec.configure do |config|
  config.include SignInHelpers, type: :request
  config.include SystemSignInHelpers, type: :system
end
