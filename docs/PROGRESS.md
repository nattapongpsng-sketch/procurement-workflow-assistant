# PROGRESS

## M0 Groundwork — เสร็จ 13 พ.ย. 2569 (รอตรวจด้วยตา 2 ข้อ ดูท้ายหัวข้อ)

| # | ส่งมอบ | สถานะ | หลักฐาน |
|---|---|---|---|
| 1 | Rails 8.1 + SQLite (ย้ายเป็น PostgreSQL ใน M0.5) + Tailwind + importmap, Docker Compose dev, bin/setup, .env.example, README | ✅ | `bin/setup --skip-server` ผ่าน; `docker compose up --build` ผ่าน (15 พ.ย. 2569: web healthy, ค้นหา/หน้าขั้นตอนตอบ 200, worker ใน container สร้างเอกสารทั้ง 2 ฉบับสำเร็จ) |
| 2 | โครงสร้าง app/services, app/components, app/templates/docx, db/seeds/workflows, lib/thai | ✅ | |
| 3 | Models + migrations + validations + seed จาก YAML (workflow AI ≤ 50,000 ครบ 9 ขั้น 53 ฟิลด์ + Recommended List 23 รายการ) | ✅ | `bin/rails db:seed` รันซ้ำได้ไม่สร้างข้อมูลซ้ำ (`spec/services/seed_loader_spec.rb`) |
| 4 | lib ภาษาไทย + unit test | ✅ | `spec/lib/thai_spec.rb` 30 ตัวอย่าง (เอ็ด/ยี่, ล้าน, สตางค์, วันที่เต็ม/ย่อ, `7,990.-`) |
| 5 | DocumentGenerator (Sablon, Solid Queue, Active Storage) + golden test | ✅ | `spec/services/document_generator_spec.rb`; ทดสอบ Solid Queue จริงใน development แล้ว (job → succeeded, ไฟล์ 84 KB) |
| 6 | CLAUDE.md | ✅ | |
| 7 | ROADMAP / PROGRESS / OPEN_QUESTIONS | ✅ | |
| 8 | rubocop, brakeman, RSpec ใน CI | ✅ | CI เขียวทั้ง 4 job (lint, scan_ruby, scan_js, test) บน https://github.com/nattapongpsng-sketch/procurement-workflow-assistant — รอบแรกแดงเพราะ `db:prepare` seed DB ทดสอบ แก้เป็น `db:schema:load` แล้ว |

นอกเหนือแผน: หน้า "ค้นหา Workflow" และ "ขั้นตอนทั้งหมด" แบบพื้นฐาน + ViewComponent 5 ตัว ตาม design tokens ของ UI canvas

## M0.5 ปรับฐาน — เสร็จ 15 พ.ย. 2569

ตาม [REPLAN.md](REPLAN.md) หลังได้ [Requirement.md](Requirement.md) · GitHub milestone "M0.5 ปรับฐาน"

| # | งาน | สถานะ | หลักฐาน |
|---|---|---|---|
| 1 | PostgreSQL 17 แทน SQLite (jsonb, Solid Queue บน Postgres, compose `db`, `script/backup_db`) | ✅ | spec ทั้งหมดผ่านบน Postgres, CI มี postgres service, ทดสอบ job จริงใน Docker |
| 2 | CI บน GitHub: postgres + LibreOffice + ฟอนต์, spec PDF ต้องผ่าน (ไม่ข้าม) | ✅ | CI เขียว, log แสดง 0 pending |
| 3 | PDF ฝังฟอนต์จาก template เดิม (LibreOffice headless) | ✅ | A4, ฝัง THSarabunNew; วัดใน Docker 4.3 วินาที/ชุด 2 ฉบับ (NFR-04 ≤ 5 วินาที) |
| 4 | ฟอนต์ TH Sarabun New ในทุก template | ✅ | GPL v2+ พร้อม font exception, fsType 0; ดาวน์โหลด + ตรวจ checksum ตอน build |
| 5 | ผู้ใช้ / 8 บทบาท / ส่วนงาน / ตำแหน่ง, login ภาษาไทย, หน้าตั้งค่า Admin | ✅ | request + model specs; ผู้ใช้ตัวอย่าง (ชื่อสมมติ) เฉพาะ dev |
| 6 | Audit log แก้/ลบไม่ได้ (PostgreSQL trigger) + หน้าดูย้อนหลัง | ✅ | spec พิสูจน์ว่า UPDATE/DELETE/TRUNCATE ด้วย SQL ตรงถูกปฏิเสธ |
| 7 | คำนวณ VAT (แยก/รวม/ไม่มี) และภาษีหัก ณ ที่จ่าย | ✅ | 12 spec ครอบคลุมการปัดเศษ; อัตรารอฝ่ายการเงินยืนยัน (Q36) |

ระหว่างทำพบและแก้: ช่องลงนามใน template แคบจนชื่อยาวถูกตัด + มีกรอบเส้นที่ฉบับจริงไม่มี (ขยาย เอากรอบออก ให้ขยายตามข้อความ),
หน้าว่างท้ายรายงานขอซื้อ, รายงานผลล้นเป็น 2 หน้าเมื่อเป็น PDF, ไฟล์ที่ container สร้างเป็นของ root (ให้ container รันด้วย uid ของผู้ใช้)

ยังไม่ได้ทำใน M0.5 (ย้ายไป M1/M2 ตามแผน): หน้าตั้งค่าเกณฑ์วงเงิน/อัตราภาษี (FR-03), การแยกสิทธิ์การมองเห็นเรื่องตามส่วนงาน (ใช้จริงเมื่อมีคำขอใน M1), SoD ในขั้นอนุมัติ/ตรวจรับ (M2/M3)

## หลัง M0

- 15 พ.ย. 2569 — ตัดสิน Q2, Q8, Q12, Q13, Q14, Q22 (ดู OPEN_QUESTIONS "ตอบแล้ว"); แก้คำผิดชัด 2 จุดในรายงานผลการพิจารณา; ข้อกฎหมาย/ภาษีที่เหลือแยกเป็น Q34, Q35
- 15 พ.ย. 2569 — ลบ gem `image_processing`/libvips ที่ไม่ได้ใช้; merge PR อัปเดต GitHub Actions ของ Dependabot (#1–#3)
- 15 พ.ย. 2569 — เพิ่มเอกสาร **รายงานผลการพิจารณาและอนุมัติสั่งซื้อ** (`result_report.docx`) สร้างจาก PDF ตามที่อนุมัติใน Q28 และ workflow `ai_purchase_under_50k` **v2** (v1 คงเดิม) golden test: `spec/services/result_report_spec.rb`

### รอตรวจ

- [ ] เปิดเอกสารตัวอย่าง (.docx ใน Word และ PDF) เทียบกับแบบฟอร์มจริง — PDF ตรวจด้วยตาแล้วโดย Claude, ยังไม่มีคนตรวจ (ตำแหน่งช่องลงนามของรายงานผลประมาณจากภาพ PDF)
- [x] `docker compose up --build` — ตรวจแล้ว 15 พ.ย. 2569

### การตัดสินใจระหว่าง M0

- ใช้ Sablon ได้กับแบบฟอร์มจริง ไม่ต้องเปลี่ยนเครื่องมือ
- model ชื่อ `ProcurementCase` แทน `Case` (keyword ของ Ruby)
- คงฟอนต์ TH SarabunPSK ตามไฟล์จริงไว้ก่อน (Q22)
- golden test ใช้ยอด 7,990 ตาม template (Q1) — ต่างจากต้นฉบับ 4 จุดที่ตั้งใจ ดู `spec/fixtures/golden/README.md`
- ภาพหน้าราคาจริงใน template ถูกแทนด้วยภาพ placeholder สีเทา และใส่ภาพของแต่ละเรื่องผ่าน Sablon (Q25)
- development ใช้ Solid Queue เหมือน production
