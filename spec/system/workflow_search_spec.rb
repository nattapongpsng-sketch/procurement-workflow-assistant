require "rails_helper"

RSpec.describe "Searching for a workflow" do
  before { SeedLoader.call }

  it "finds the AI purchase workflow and shows all its steps" do
    visit root_path
    fill_in "ค้นหา workflow", with: "ซื้อ AI"
    click_button "ค้นหา"

    expect(page).to have_text("พบ 1 workflow สำหรับ “ซื้อ AI”")
    click_link "ดูขั้นตอน"

    expect(page).to have_css("h1", text: "จัดซื้อโปรแกรม AI วงเงินไม่เกิน 50,000 บาท")
    expect(page).to have_text("ขั้นตอนทั้งหมด (9 ขั้น)")
    expect(page).to have_text("จัดทำรายงานขอซื้อขอจ้าง")
    expect(page).to have_text("รอยืนยันกับเจ้าหน้าที่พัสดุ", count: 4)
    expect(page).to have_text("รายงานขอซื้อขอจ้าง (.docx)")
    expect(page).to have_text("50,000 บาท")
  end

  it "explains what to do when nothing matches" do
    visit root_path(q: "รถยนต์")

    expect(page).to have_text("ยังไม่พบ workflow ที่ตรงกับ “รถยนต์”")
  end

  it "returns 404 for unknown workflows" do
    visit workflow_path("nope-v1")

    expect(page).to have_http_status(:not_found)
  end
end
