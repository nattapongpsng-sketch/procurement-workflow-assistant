# PROGRESS

## M0 Groundwork — เสร็จ 13 พ.ย. 2569 (รอตรวจด้วยตา 2 ข้อ ดูท้ายหัวข้อ)

| # | ส่งมอบ | สถานะ | หลักฐาน |
|---|---|---|---|
| 1 | Rails 8.1 + SQLite + Tailwind + importmap, Docker Compose dev, bin/setup, .env.example, README | ✅ | `bin/setup --skip-server` ผ่าน; `docker compose up --build` ผ่าน (15 พ.ย. 2569: web healthy, ค้นหา/หน้าขั้นตอนตอบ 200, worker ใน container สร้างเอกสารทั้ง 2 ฉบับสำเร็จ) |
| 2 | โครงสร้าง app/services, app/components, app/templates/docx, db/seeds/workflows, lib/thai | ✅ | |
| 3 | Models + migrations + validations + seed จาก YAML (workflow AI ≤ 50,000 ครบ 9 ขั้น 53 ฟิลด์ + Recommended List 23 รายการ) | ✅ | `bin/rails db:seed` รันซ้ำได้ไม่สร้างข้อมูลซ้ำ (`spec/services/seed_loader_spec.rb`) |
| 4 | lib ภาษาไทย + unit test | ✅ | `spec/lib/thai_spec.rb` 30 ตัวอย่าง (เอ็ด/ยี่, ล้าน, สตางค์, วันที่เต็ม/ย่อ, `7,990.-`) |
| 5 | DocumentGenerator (Sablon, Solid Queue, Active Storage) + golden test | ✅ | `spec/services/document_generator_spec.rb`; ทดสอบ Solid Queue จริงใน development แล้ว (job → succeeded, ไฟล์ 84 KB) |
| 6 | CLAUDE.md | ✅ | |
| 7 | ROADMAP / PROGRESS / OPEN_QUESTIONS | ✅ | |
| 8 | rubocop, brakeman, RSpec ใน CI | ✅ | CI เขียวทั้ง 4 job (lint, scan_ruby, scan_js, test) บน https://github.com/nattapongpsng-sketch/procurement-workflow-assistant — รอบแรกแดงเพราะ `db:prepare` seed DB ทดสอบ แก้เป็น `db:schema:load` แล้ว |

นอกเหนือแผน: หน้า "ค้นหา Workflow" และ "ขั้นตอนทั้งหมด" แบบพื้นฐาน + ViewComponent 5 ตัว ตาม design tokens ของ UI canvas

## หลัง M0

- 15 พ.ย. 2569 — ตัดสิน Q2, Q8, Q12, Q13, Q14, Q22 (ดู OPEN_QUESTIONS "ตอบแล้ว"); แก้คำผิดชัด 2 จุดในรายงานผลการพิจารณา; ข้อกฎหมาย/ภาษีที่เหลือแยกเป็น Q34, Q35
- 15 พ.ย. 2569 — ลบ gem `image_processing`/libvips ที่ไม่ได้ใช้; merge PR อัปเดต GitHub Actions ของ Dependabot (#1–#3)
- 15 พ.ย. 2569 — เพิ่มเอกสาร **รายงานผลการพิจารณาและอนุมัติสั่งซื้อ** (`result_report.docx`) สร้างจาก PDF ตามที่อนุมัติใน Q28 และ workflow `ai_purchase_under_50k` **v2** (v1 คงเดิม) golden test: `spec/services/result_report_spec.rb`

### รอตรวจ

- [ ] เปิด `tmp/samples/purchase_request_sample.docx` และ `tmp/samples/result_report_sample.docx` (`bin/rails docs:render_sample`) ใน Word เทียบกับแบบฟอร์มจริง/PDF — ยังไม่มีใครเปิดด้วย Word (ตำแหน่งช่องลงนามของรายงานผลประมาณจากภาพ PDF)
- [x] `docker compose up --build` — ตรวจแล้ว 15 พ.ย. 2569

### การตัดสินใจระหว่าง M0

- ใช้ Sablon ได้กับแบบฟอร์มจริง ไม่ต้องเปลี่ยนเครื่องมือ
- model ชื่อ `ProcurementCase` แทน `Case` (keyword ของ Ruby)
- คงฟอนต์ TH SarabunPSK ตามไฟล์จริงไว้ก่อน (Q22)
- golden test ใช้ยอด 7,990 ตาม template (Q1) — ต่างจากต้นฉบับ 4 จุดที่ตั้งใจ ดู `spec/fixtures/golden/README.md`
- ภาพหน้าราคาจริงใน template ถูกแทนด้วยภาพ placeholder สีเทา และใส่ภาพของแต่ละเรื่องผ่าน Sablon (Q25)
- development ใช้ Solid Queue เหมือน production
