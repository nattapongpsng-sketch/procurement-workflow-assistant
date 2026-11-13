require "rails_helper"

RSpec.describe "base components", type: :component do
  it "renders a contained button as a link when given href" do
    render_inline(ButtonComponent.new("ดูขั้นตอน", href: "/workflows/x"))

    expect(page).to have_link("ดูขั้นตอน", href: "/workflows/x")
    expect(page).to have_css("a.bg-primary")
  end

  it "renders a disabled button instead of a link" do
    render_inline(ButtonComponent.new("ยังไม่เปิดใช้", href: "/x", disabled: true))

    expect(page).to have_button("ยังไม่เปิดใช้", disabled: true)
    expect(page).to have_no_link
  end

  it "rejects unknown variants" do
    expect { ButtonComponent.new("x", variant: :ghost) }.to raise_error(KeyError)
  end

  it "renders badges and callouts by tone" do
    render_inline(BadgeComponent.new("พร้อมใช้งาน", tone: :success))
    expect(page).to have_css("span.bg-success-soft", text: "พร้อมใช้งาน")

    render_inline(CalloutComponent.new(tone: :error, title: "ไม่ผ่านเงื่อนไข").with_content("เหตุผล"))
    expect(page).to have_css("[role=alert]", text: "ไม่ผ่านเงื่อนไขเหตุผล")
  end

  it "marks the current page in the header" do
    render_inline(AppHeaderComponent.new(current: "search"))

    expect(page).to have_link("ค้นหา Workflow", href: "/")
    expect(page).to have_css("a[aria-current=page]", text: "ค้นหา Workflow")
  end

  it "explains a field with help, example and reason" do
    field = build(:field_definition, key: "item.name", help: "ชื่อพัสดุตามผู้ขาย", example: "Claude Pro", why: "ใช้ในชื่อเรื่อง")
    render_inline(FieldHelpComponent.new(field))

    expect(page).to have_text("ชื่อพัสดุตามผู้ขาย")
    expect(page).to have_text("ตัวอย่าง: Claude Pro")
    expect(page).to have_text("ทำไมต้องกรอก: ใช้ในชื่อเรื่อง")
  end

  it "does not render help for computed fields" do
    render_inline(FieldHelpComponent.new(build(:field_definition, :computed)))

    expect(page).to have_no_css("div")
  end
end
