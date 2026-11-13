# PROGRESS

## M0 Groundwork — เสร็จ 13 พ.ย. 2569 (รอตรวจด้วยตา 2 ข้อ ดูท้ายหัวข้อ)

| # | ส่งมอบ | สถานะ | หลักฐาน |
|---|---|---|---|
| 1 | Rails 8.1 + SQLite + Tailwind + importmap, Docker Compose dev, bin/setup, .env.example, README | ✅ | `bin/setup --skip-server` ผ่าน; `docker compose config` ผ่าน (ยังไม่ได้ build image เพราะ Docker daemon ปิดอยู่ตอนทดสอบ) |
| 2 | โครงสร้าง app/services, app/components, app/templates/docx, db/seeds/workflows, lib/thai | ✅ | |
| 3 | Models + migrations + validations + seed จาก YAML (workflow AI ≤ 50,000 ครบ 9 ขั้น 53 ฟิลด์ + Recommended List 23 รายการ) | ✅ | `bin/rails db:seed` รันซ้ำได้ไม่สร้างข้อมูลซ้ำ (`spec/services/seed_loader_spec.rb`) |
| 4 | lib ภาษาไทย + unit test | ✅ | `spec/lib/thai_spec.rb` 30 ตัวอย่าง (เอ็ด/ยี่, ล้าน, สตางค์, วันที่เต็ม/ย่อ, `7,990.-`) |
| 5 | DocumentGenerator (Sablon, Solid Queue, Active Storage) + golden test | ✅ | `spec/services/document_generator_spec.rb`; ทดสอบ Solid Queue จริงใน development แล้ว (job → succeeded, ไฟล์ 84 KB) |
| 6 | CLAUDE.md | ✅ | |
| 7 | ROADMAP / PROGRESS / OPEN_QUESTIONS | ✅ | |
| 8 | rubocop, brakeman, RSpec ใน CI | ✅ ในเครื่อง | rubocop 0 offense, brakeman 0 warning (1 รายการ ignore พร้อมเหตุผล), bundler-audit/importmap audit ไม่พบช่องโหว่, RSpec 87 ตัวอย่างผ่าน — CI จะรันจริงเมื่อ push ขึ้น GitHub (Q26) |

นอกเหนือแผน: หน้า "ค้นหา Workflow" และ "ขั้นตอนทั้งหมด" แบบพื้นฐาน + ViewComponent 5 ตัว ตาม design tokens ของ UI canvas

### รอตรวจ

- [ ] เปิด `tmp/samples/purchase_request_sample.docx` (`bin/rails docs:render_sample`) ใน Word เทียบกับแบบฟอร์มจริง — ยังไม่มีใครเปิดด้วย Word
- [ ] `docker compose up --build` บนเครื่องที่เปิด Docker แล้ว

### การตัดสินใจระหว่าง M0

- ใช้ Sablon ได้กับแบบฟอร์มจริง ไม่ต้องเปลี่ยนเครื่องมือ
- model ชื่อ `ProcurementCase` แทน `Case` (keyword ของ Ruby)
- คงฟอนต์ TH SarabunPSK ตามไฟล์จริงไว้ก่อน (Q22)
- golden test ใช้ยอด 7,990 ตาม template (Q1) — ต่างจากต้นฉบับ 4 จุดที่ตั้งใจ ดู `spec/fixtures/golden/README.md`
- ภาพหน้าราคาจริงใน template ถูกแทนด้วยภาพ placeholder สีเทา และใส่ภาพของแต่ละเรื่องผ่าน Sablon (Q25)
- development ใช้ Solid Queue เหมือน production
