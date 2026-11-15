require "rails_helper"

RSpec.describe "Admin settings" do
  let!(:organization) { create(:organization) }
  let!(:department) { create(:department, organization:) }
  let(:admin) { create(:user, :admin) }

  it "is closed to users without the admin role" do
    sign_in_as(create(:user, department:))

    get admin_users_path

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to include("ไม่มีสิทธิ์")
  end

  it "lets an admin create a user with several roles" do
    sign_in_as(admin)

    post admin_users_path, params: { user: { name: "นายใหม่ ทดสอบ", email_address: "new@example.com",
                                             password: "new-password-1234", password_confirmation: "new-password-1234",
                                             department_id: department.id, active: "1", roles: [ "", "requester", "inspector" ] } }

    expect(response).to redirect_to(admin_users_path)
    expect(User.find_by!(email_address: "new@example.com").roles).to eq(%w[requester inspector])
  end

  it "shows validation errors in Thai" do
    sign_in_as(admin)

    post admin_users_path, params: { user: { name: "", email_address: "bad", roles: [ "requester" ] } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("บันทึกไม่ได้")
  end

  it "keeps the password when the field is left blank" do
    user = create(:user, department:)
    sign_in_as(admin)

    patch admin_user_path(user), params: { user: { name: "ชื่อใหม่", password: "", password_confirmation: "" } }

    expect(user.reload.name).to eq("ชื่อใหม่")
    expect(user.authenticate(SignInHelpers::PASSWORD)).to be_truthy
  end

  it "stops admins from removing their own admin role or deactivating themselves" do
    sign_in_as(admin)

    patch admin_user_path(admin), params: { user: { roles: [ "", "requester" ], department_id: department.id } }
    expect(response).to have_http_status(:unprocessable_entity)
    patch admin_user_path(admin), params: { user: { roles: [ "", "admin" ], active: "0" } }
    expect(response).to have_http_status(:unprocessable_entity)

    expect(admin.reload).to be_admin.and(be_active)
  end

  it "manages departments and positions" do
    sign_in_as(admin)

    post admin_departments_path, params: { department: { code: "NEW", name: "ส่วนงานใหม่", active: "1" } }
    post admin_positions_path, params: { position: { title: "หัวหน้าแผนก", short_title: "หผ." } }

    expect(organization.departments.find_by(code: "NEW")).to be_present
    expect(organization.positions.find_by(title: "หัวหน้าแผนก").short_title).to eq("หผ.")
  end
end
