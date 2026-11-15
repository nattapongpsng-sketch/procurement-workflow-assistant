# REPLAN — ปรับโครงการตาม docs/Requirement.md

> สถานะ: **รอยืนยัน** ก่อนลงมือ · เขียน 15 พ.ย. 2569
> ตัดสินแล้ว (15 พ.ย. 2569): PostgreSQL แทน SQLite; **คงใช้ GitHub** (repo + Actions + Issues) แทน GitLab ที่ NFR-01 ระบุ

## 1. สรุปการเปลี่ยนแปลง

| เรื่อง | เดิม (brief + M0) | ใหม่ (Requirement.md) |
|---|---|---|
| ขอบเขต | จัดซื้อโปรแกรม AI ≤ 50,000 บาท | จัดซื้อ/จัดจ้าง/เช่า วิธีเฉพาะเจาะจง ≤ 100,000 บาท + เบิกจ่ายตรง (สาธารณูปโภค) |
| เส้นทาง | 1 workflow | ตามวงเงิน: ≤ 5,000 / ≤ 50,000 (ว 804 แบบย่อ) / ≤ 100,000 / เบิกจ่ายตรง — ค่าตั้งที่ Admin แก้ได้ |
| ช่วงงาน | ถึงขอยืมเงิน (M4) | คำขอ → อนุมัติตามลำดับ → ตรวจรับ → เบิกจ่าย → รายงาน (M0–M3 ใช้งานจริงได้ครบสาย) |
| ฐานข้อมูล | SQLite | **PostgreSQL** |
| Repo / CI | GitHub + Actions | GitHub เหมือนเดิม (Requirement ระบุ GitLab — เจ้าของโปรเจกต์เลือกคง GitHub), FR-xx เป็น GitHub Issue |
| เอกสาร | .docx | **PDF ฝังฟอนต์** (หลัก) + .docx (แก้ไขกรณีพิเศษ) |
| ฟอนต์ | TH SarabunPSK (Q22) | **TH Sarabun New** (NFR-04) — กลับคำตัดสิน Q22 |
| VAT | ไม่คำนวณ (Q14) | **คำนวณ VAT และภาษีหัก ณ ที่จ่าย** (FR-09, FR-19) — กลับคำตัดสิน Q14 |
| รายการ | 1 รายการ/เรื่อง | หลายบรรทัด (FR-09) |
| ผู้ใช้ | ยังไม่มี | บทบาท 8 แบบ, แยกหน้าที่ (SoD), LDAP/AD เมื่อมี |

## 2. สิ่งที่ใช้ต่อได้จาก M0

- หลักการ 6 ข้อ — โดยเฉพาะ "workflow/เกณฑ์/แบบฟอร์มเป็นข้อมูล" ตรงกับหลักการออกแบบใน Requirement
- `WorkflowTemplate` (มีเวอร์ชัน, eligibility rules) → ใช้เป็น "เส้นทาง" ตามวงเงิน/ประเภทคำขอ
- `FieldComputer`, `EligibilityEvaluator`, `lib/thai`, `DocumentGenerator` + golden test, `DocumentTemplate` มีเวอร์ชัน (FR-04)
- `BudgetSource` (ฐานของ FR-07), ViewComponent + design tokens, Docker, brakeman/rubocop/RSpec
- workflow AI ที่มีอยู่ → เก็บเป็นตัวอย่าง/เส้นทางเฉพาะของหน่วยงานนำร่อง

## 3. งานปรับฐาน (M0.5 Re-foundation) — ทำก่อน M1

| # | งาน | รายละเอียด |
|---|---|---|
| 1 | PostgreSQL | `pg` gem, database.yml (primary/queue/cache/cable บน Postgres), `json` → `jsonb` + GIN index ที่จำเป็น, compose เพิ่ม service `db` (postgres:17 มีใน Docker แล้ว), migrations ใหม่ (ยังไม่มีข้อมูลจริง จึงไม่ต้องย้ายข้อมูล) |
| 2 | GitHub | ปรับ `.github/workflows/ci.yml` ให้ test รันกับ postgres service + LibreOffice สำหรับ PDF; เพิ่ม issue templates (user story, bug) + PR template ใน `.github/`, labels `roadmap::committed` / `roadmap::tentative`, milestone M0.5–M5 และ issue FR-01…FR-28 |
| 3 | PDF | สร้าง .docx ด้วย Sablon แล้วแปลงเป็น PDF ด้วย LibreOffice headless ใน container (ไม่ต้องสร้าง layout ใหม่ ยังยึดหลักการข้อ 5) + ติดตั้งฟอนต์ TH Sarabun New ใน image; ทดสอบเวลา ≤ 5 วินาที/ชุด (NFR-04) |
| 4 | ฟอนต์ | เปลี่ยน template เป็น TH Sarabun New ผ่าน `script/docx` (กลับ Q22) |
| 5 | ผู้ใช้และสิทธิ์ | `User` + บทบาท (หลายบทบาทต่อคน), ส่วนงาน/ตำแหน่ง (FR-01), Rails 8 authentication generator (LDAP/AD ภายหลัง), policy แยกสิทธิ์ตามส่วนงาน (NFR-05) |
| 6 | Audit log | ตาราง append-only (insert-only ระดับ DB ด้วย trigger ใน Postgres) บันทึกทุกการสร้าง/แก้/อนุมัติ/ยกเลิก (FR-28) |
| 7 | เงินและภาษี | `lib/thai` + `Money`/`Tax` service: VAT 7% (รวมใน/แยกนอก), ภาษีหัก ณ ที่จ่ายตามประเภทเงินได้, กฎการปัดเศษเขียนเป็น test (NFR-02) |

## 4. Roadmap ที่เสนอ (แทน docs/ROADMAP.md เดิม)

Requirement มีแผนภาพ Milestone ที่ฝังมา แต่เนื้อหาไม่ได้ติดมาในไฟล์ ด้านล่างจึงเป็นข้อเสนอที่จัดจากระดับความสำคัญ (Must/Should/Could) — ปรับตามแผนภาพจริงได้

| Milestone | FR / NFR | เกณฑ์สำเร็จ |
|---|---|---|
| **M0.5 ปรับฐาน** | NFR-01/02/04/05/06, FR-01, FR-21, FR-28 | CI บน GitHub เขียว, ระบบรันบน Postgres, ได้ PDF ฝังฟอนต์จาก template เดิม, login + บทบาท, audit log |
| **M1 คำขอและเอกสาร** | FR-03–FR-12, FR-22, FR-23, (FR-07, FR-13 Should) | สร้างคำขอซื้อ/จ้าง/เช่า/เบิกจ่ายตรงหลายรายการ ระบบเลือกเส้นทางตามวงเงิน บล็อก > 100,000 เตือนแบ่งซื้อ ได้เอกสารชุดแรกพร้อมเลขที่อัตโนมัติ |
| **M2 อนุมัติตามลำดับ** | FR-02, FR-14, FR-15, (FR-16, FR-17 Should) | เรื่องเดินตามลำดับขั้นจากวงเงินอำนาจ อนุมัติ/ไม่อนุมัติ/ส่งกลับพร้อมเหตุผล มีการมอบอำนาจแทน และกัน SoD |
| **M3 ตรวจรับ เบิกจ่าย รายงาน + นำร่อง** | FR-18, FR-19, FR-20, FR-24, FR-25 | ครบสาย: คำขอ → อนุมัติ → ตรวจรับ → เบิกจ่าย, ค้นหา/ดาวน์โหลดทั้งชุด, สขร.1 ส่งออก Excel, ใช้จริงในหน่วยงานนำร่อง 1 แห่ง |
| M4 (tentative) | FR-26, เส้นทาง ว 804 ส่วนที่เหลือ, LDAP/AD | ส่งออกช่อง e-GP, สรุปรายไตรมาส |
| M5 (tentative) | FR-27, ผู้ช่วย AI (จากแผนเดิม) | Dashboard เทียบงบ |

M0.5–M3 ติด label `roadmap::committed`, M4 เป็นต้นไป `roadmap::tentative` (ตาม Requirement) — ใช้ GitHub labels/milestones

## 5. สิ่งที่ต้องได้ก่อนเริ่ม

| # | สิ่งที่ต้องการ | ใช้ใน |
|---|---|---|
| R1 | ~~GitLab project~~ — ตอบแล้ว: ใช้ GitHub repo เดิม | — |
| R2 | เนื้อหาของแผนภาพที่ฝังไว้ 2 รูป: กระบวนการหลัก (จัดซื้อ 8 ขั้น + เบิกจ่ายตรง 2 ขั้น) และ Milestone M0–M5 | M1, ROADMAP |
| R3 | แบบฟอร์มจริงของงานทั่วไป ≤ 100,000 (ตอนนี้มีเฉพาะชุดจัดซื้อ AI) — Requirement ระบุว่าต้องได้ก่อน M2 | M1–M3 |
| R4 | คำถามในหัวข้อ "คำถามที่ต้องตัดสินใจก่อนเริ่ม" ของ Requirement (ระเบียบที่ใช้, e-GP/ว 714–715, มอบอำนาจ, น้ำมัน Fleet Card, สาธารณูปโภค, ลายมือชื่ออิเล็กทรอนิกส์, หน่วยงานนำร่อง) — ไม่ขวาง M0.5 แต่ขวาง M1–M2 | M1–M3 |
| R5 | คำถามข้อ "แทนระบบประมูลทั้งหมด หรือแยกเป็น GitLab project ใหม่" ดูเหมือนติดมาจากโครงการระบบประมูล — ยืนยันว่าตัดทิ้งได้ | — |

## 6. ผลกระทบต่อเอกสารเดิม (ทำเมื่อยืนยันแผน)

- `docs/ROADMAP.md` → แทนด้วยหัวข้อ 4, `docs/PROGRESS.md` เพิ่ม M0.5
- `docs/OPEN_QUESTIONS.md` → กลับ Q14 (คำนวณ VAT) และ Q22 (TH Sarabun New); Q34 ปิดตามเกณฑ์ใน Requirement (≤ 100,000 ผู้ตรวจรับ 1 คน — ยังต้องให้เจ้าหน้าที่พัสดุยืนยันตามที่ Requirement เขียนไว้); เพิ่ม R1–R5
- `CLAUDE.md` → stack (PostgreSQL), ฟอนต์, VAT, ขอบเขตใหม่; บันทึกว่าคง GitHub แม้ NFR-01 ระบุ GitLab
- `docs/DOMAIN.md` → เพิ่มคำศัพท์ e-GP, สขร.1, ว 804, ภาษีหัก ณ ที่จ่าย, บทบาทใหม่
