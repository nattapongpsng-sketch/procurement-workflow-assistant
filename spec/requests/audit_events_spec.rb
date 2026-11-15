require "rails_helper"

RSpec.describe "Audit log viewer" do
  let(:department) { create(:department) }

  it "records sign-in and lets auditors read the log" do
    auditor = create(:user, roles: [ "auditor" ], department: nil)
    sign_in_as(auditor)

    get audit_events_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ประวัติการใช้งาน", "เข้าสู่ระบบ", auditor.email_address)
  end

  it "filters by type and action" do
    admin = create(:user, :admin)
    create(:person, full_name: "บุคคล กรอง")
    sign_in_as(admin)

    get audit_events_path(auditable_type: "Person", action_name: "create")

    expect(response.body).to include("บุคคล กรอง")
    expect(response.body).not_to include(admin.email_address)
  end

  it "is closed to other roles" do
    sign_in_as(create(:user, department:))

    get audit_events_path

    expect(response).to redirect_to(root_path)
  end
end
