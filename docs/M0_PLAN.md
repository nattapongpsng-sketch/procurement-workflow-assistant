# แผน M0 — Groundwork

> สถานะ: **implement แล้ว** (13 พ.ย. 2569) — ผลและส่วนที่ต่างจากแผนดู [PROGRESS.md](PROGRESS.md)

## 1. การประเมิน Sablon กับแบบฟอร์มจริง

**ข้อสรุป: ใช้ Sablon ได้** ไม่ต้องเปลี่ยนเครื่องมือ

| ประเด็นใน template | วิธีจัดการ |
|---|---|
| ข้อความแตกเป็น run ย่อย (~370 run) | สร้างสำเนา template แล้ว "รวม run" ตรงจุดที่จะใส่ field ให้เหลือ run เดียวที่คง `rPr` เดิม (TH SarabunPSK 16pt) แล้วแทนด้วย `MERGEFIELD =key` — ส่วนอื่นของไฟล์ไม่แตะ |
| ช่องลงนามเป็น text box (ข้อความซ้ำใน `mc:Choice` และ VML fallback) | ใส่ field ทั้งสองชุด มี spec ตรวจว่าทั้งสองชุดถูกแทนค่า |
| ตารางหัวหนังสือ (จาก/ถึง/เลขที่/วันที่/เรื่อง/เรียน) | field ในเซลล์ตาราง Sablon รองรับ |
| ผู้ตรวจรับหลายคน (list) | `MERGEFIELD people.inspectors:each(i)` … `:endEach` |
| ข้อความที่มีหรือไม่มีก็ได้ (เช่น "(200 USD โดยคิด 1 USD = 34 บาท)") | `MERGEFIELD price.foreign_amount:if` … `:endIf` |
| ค่าที่คำนวณ (เงินตัวอักษร วันที่ไทย) | คำนวณใน Ruby ก่อน (`DocumentContext`) Sablon รับเฉพาะ string ที่จัดรูปแล้ว ไม่มี logic ใน template |
| ภาพหน้าราคา (เอกสารแนบ 3) | Sablon รองรับ image field — M0 ทำถ้าไม่ยืดเวลา ไม่งั้นคงภาพเดิมไว้ก่อน (Q25) |

วิธีใส่ field: เขียนสคริปต์ `bin/prepare_template` (Ruby + Nokogiri) แปลงจากต้นฉบับ → `app/templates/docx/purchase_request.docx` แบบทำซ้ำได้ และ commit ทั้งสคริปต์และผลลัพธ์ เพื่อให้ตรวจได้ว่าแก้อะไรในไฟล์ต้นฉบับบ้าง (หลักการข้อ 5)

ความเสี่ยง: ถ้า Sablon ไม่รองรับ Ruby/Rails เวอร์ชันที่เลือก จะ fork หรือ pin เวอร์ชัน แล้วบันทึกไว้ ทางสำรองคือ docx-templater แบบ `{{placeholder}}` ด้วย Nokogiri ล้วน (จะเสนอก่อนเปลี่ยน)

## 2. Stack ที่จะติดตั้ง

- Ruby **3.4.x** (pin ใน `.ruby-version` + `mise.toml`, ตาม Q21) · Rails 8.x · SQLite (dev/test/production) · Solid Queue/Cache/Cable บน SQLite
- `rails new . --database=sqlite3 --css=tailwind --skip-test --skip-jbuilder` (ใช้ importmap ตาม default)
- gems: `view_component`, `sablon`, `rspec-rails`, `factory_bot_rails`, `capybara`, `selenium-webdriver` (system spec), `rubocop-rails-omakase`, `brakeman`, `bundler-audit`
- ไฟล์ DB และ Active Storage อยู่ใน `storage/` ซึ่ง mount เป็น volume (`compose.yaml`) — มี `script/backup_sqlite` (ใช้ `sqlite3 .backup`) + ตัวอย่าง cron และหมายเหตุ Litestream ใน README

## 3. โครงสร้างโค้ด

```
app/
  models/            WorkflowTemplate, WorkflowStep, FieldDefinition, DocumentTemplate,
                     WorkflowDocument (join), RecommendedAi, Person, BudgetSource,
                     Case, GeneratedDocument
  services/
    workflow_search.rb         ค้นหา + ให้คะแนน (M0: keyword scoring ใน Ruby — FTS5 ของ SQLite ตัดคำไทยไม่ได้)
    eligibility_evaluator.rb   ประเมิน rule แบบ declarative → ผ่าน/ไม่ผ่าน + เหตุผล + ทางเลือก
    field_computer.rb          คำนวณ computed field จาก whitelist ฟังก์ชัน (ไม่ eval)
    document_context.rb        case.data + reference data + computed → hash ที่จัดรูปแล้วสำหรับ template
    document_generator.rb      Sablon render → GeneratedDocument + Active Storage
    workflow_loader.rb         โหลด/validate YAML → records (idempotent ตาม code+version)
  jobs/generate_document_job.rb  (Solid Queue)
  components/        ButtonComponent, BadgeComponent, CalloutComponent, FieldHelpComponent,
                     AppHeaderComponent (ตาม UI mockup)
  templates/docx/    purchase_request.docx (มี MERGEFIELD)
db/seeds/
  workflows/ai_purchase_under_50k.v1.yml
  reference/recommended_ai.yml   (23 รายการ)
  reference/people.yml           (ชื่อสมมติทั้งหมด)
  reference/budget_sources.yml
lib/thai/            baht_text.rb, date_format.rb, money.rb  (module Thai)
spec/                lib/thai, models, services, jobs, system (smoke), fixtures/golden/
```

## 4. Data model

| ตาราง | คอลัมน์หลัก | หมายเหตุ |
|---|---|---|
| `workflow_templates` | code, version, name, description, keywords (json), category, procurement_method, legal_basis (json), eligibility_rules (json), status (draft/published/archived), source_digest | unique (code, version); published แล้วแก้ไม่ได้ → แก้ = version ใหม่ |
| `workflow_steps` | workflow_template_id, position, title, description, actor_role, output_documents (json), required_attachments (json), tips, estimated_duration, confirmed (bool) | `confirmed: false` สำหรับขั้นที่อนุมาน (6–9) |
| `field_definitions` | workflow_template_id, key, label, group, position, field_type, required, help, example, why, validation (json), computed (json), options (json) | `why` = เหตุผลว่าทำไมต้องกรอก (หลักการข้อ 6) |
| `document_templates` | code, version, name, field_keys (json) + Active Storage `docx_file` | ไฟล์ต้นทางอยู่ใน repo, seed แนบเข้า Active Storage |
| `workflow_documents` | workflow_template_id, document_template_id, step_position | |
| `recommended_ais` | name, category, capability, vendor, list_version, approved_on, active | |
| `people` | title_prefix, full_name, position_short, position_en, employee_code, unit_code | seed ชื่อสมมติ |
| `budget_sources` | ref_doc_no, ref_doc_date, owner_unit, budget_type, fiscal_year, account_name, account_code, cost_center, limit_amount, limit_basis, spend_deadline | |
| `cases` | workflow_template_id (ผูก version), title, status, data (json), created_by (string ใน M0, ผูก User ใน M2) | |
| `generated_documents` | case_id, document_template_id, version (นับต่อ case+template), data_snapshot (json), generated_at, status, error + Active Storage `file` | |

จำนวนเงินเก็บเป็น **สตางค์ (integer)** หรือ BigDecimal string ใน `data` — ไม่ใช้ float

### ตัวอย่าง YAML (ย่อ)

```yaml
code: ai_purchase_under_50k
version: 1
name: จัดซื้อโปรแกรม AI วงเงินไม่เกิน 50,000 บาท (วิธีเฉพาะเจาะจง)
procurement_method: เฉพาะเจาะจง
legal_basis: ["พ.ร.บ.จัดซื้อจัดจ้างฯ 2560 ม.56(2)(ข)", "ระเบียบกระทรวงการคลังฯ 2560 ข้อ 79"]
eligibility_rules:
  - id: in_recommended_list
    check: { in_reference: { field: item.ai_product, table: recommended_ai } }
    fail: { reason: "โปรแกรมนี้ไม่อยู่ใน Recommended List", alternatives: [ai_not_in_list] }
  - id: max_50k
    check: { lte: [budget.total, 50000] }
    fail: { reason: "วงเงินเกิน 50,000 บาท ต้องให้คณะกรรมการบริหารและจัดหาระบบคอมพิวเตอร์เห็นชอบก่อน", alternatives: [ai_purchase_over_50k] }
fields:
  - key: budget.total
    label: วงเงินที่จะซื้อ
    type: money
    computed: { fn: multiply, args: [price.unit_price, item.quantity] }
    help: คำนวณจากราคาต่อหน่วย × จำนวน
    why: ใช้ในข้อ 4 ของรายงานขอซื้อ และเป็นยอดเงินยืม
steps: [...]
documents: [purchase_request]
```

Rule operators (M0): `lte`, `gte`, `present`, `in_reference`, `all`, `any` · Computed functions: `multiply`, `sum`, `baht_text`, `money`, `thai_date`, `thai_date_short`, `doc_number`, `concat`

## 5. lib/thai (Ruby, snake_case)

| ฟังก์ชัน | ตัวอย่าง test |
|---|---|
| `Thai.baht_text(7990)` | เจ็ดพันเก้าร้อยเก้าสิบบาทถ้วน · 6,800 → หกพันแปดร้อยบาทถ้วน · 1,350,000 → หนึ่งล้านสามแสนห้าหมื่นบาทถ้วน · 21 → ยี่สิบเอ็ดบาทถ้วน · 101 → หนึ่งร้อยเอ็ดบาทถ้วน · 11 → สิบเอ็ด · 0.50 → ห้าสิบสตางค์ · 1,000,001 · ค่าลบ/nil → error |
| `Thai.date(d)` / `Thai.date(d, format: :short)` | 2026-07-17 → "17 กรกฎาคม 2569" / "17 ก.ค. 2569" |
| `Thai.money(7990)` | "7,990.-" · 7990.5 → "7,990.50" · 1350000 → "1,350,000.-" |
| `Thai.doc_number("สชก.(บก-ท)", 617, 2569)` | "สชก.(บก-ท) 617/2569" · no = nil → "สชก.(บก-ท)      /2569" (เว้นช่องตามแบบฟอร์ม) |

## 6. DocumentGenerator + golden test

1. `GenerateDocumentJob.perform_later(case, document_template)` → `DocumentContext.build(case)` → Sablon render → แนบ `GeneratedDocument.file` + เก็บ `data_snapshot`
2. Golden test (`spec/services/document_generator_spec.rb`):
   - fixture case ใช้ข้อมูลตาม template docx (ยอด 7,990 ตาม Q1) แต่เปลี่ยน**ชื่อบุคคลเป็นชื่อสมมติ**และไม่มีรหัสพนักงานจริง
   - `spec/fixtures/golden/purchase_request.txt` = ข้อความของต้นฉบับ (แทนชื่อเป็นชื่อสมมติ) เรียงตามย่อหน้า + ตาราง + text box
   - เทียบข้อความที่แยกจากไฟล์ที่ generate ทีละย่อหน้า (normalize เฉพาะช่องว่างซ้ำ) → ต้องตรงทั้งหมด
   - ตรวจโครงสร้าง: zip ถูกต้อง, ทุก XML part parse ได้, ไม่มี MERGEFIELD หลงเหลือ, ฟอนต์/ขนาดในส่วนที่แทนค่าเหมือนต้นฉบับ, รูปโลโก้ยังอยู่
   - (ถ้าเครื่องมี LibreOffice) แปลงเป็น PDF ได้โดยไม่ error — tag `:libreoffice` ข้ามเมื่อไม่มี (Q27)
3. `rake docs:render_sample` สร้างไฟล์ตัวอย่างไว้ให้เปิดใน Word ตรวจด้วยตา

## 7. UI ใน M0 (เท่าที่จำเป็นต่อ groundwork)

ตาม UI mockup (canvas "Procurement Workflow Assistant — MVP Design")
- ย้าย design tokens ชุด "ชวนกิน" (สี รัศมี เงา ตัวอักษร) เข้า Tailwind v4 `@theme` ใน `app/assets/tailwind/application.css`
- layout หลัก + `AppHeaderComponent` (โลโก้ "จัดซื้อง่าย", เมนู ค้นหา Workflow / เรื่องของฉัน) และ component พื้นฐาน Button / Badge / Callout / FieldHelp พร้อม component spec
- หน้าแรกเป็นหน้าค้นหาแบบง่ายที่แสดง workflow จาก seed (ทำให้ system spec smoke test มีอะไรให้ทดสอบ) — หน้าจอเต็มทั้ง 5 หน้าเป็นงาน M1

## 8. Docker / CI / เอกสาร

- `Dockerfile` (production ของ Rails 8 ที่ generate มา) + `Dockerfile.dev` + `compose.yaml` (service `web` รัน `bin/dev`, `jobs` รัน `bin/jobs`, volume `storage`)
- `bin/setup` (bundle, db:prepare, seed), `.env.example`, `config/credentials` ไม่ commit master.key
- `.github/workflows/ci.yml`: jobs `lint` (rubocop), `security` (brakeman, bundler-audit, importmap audit), `test` (rspec รวม system spec แบบ headless Chrome)
- `README.md`, `CLAUDE.md`, `docs/ROADMAP.md` (M1–M5), `docs/PROGRESS.md`, อัปเดต `docs/OPEN_QUESTIONS.md`
- `.gitignore` เพิ่ม `docs/samples/` (ตาม Q20 จนกว่าจะอนุญาต)

## 9. ลำดับ commit (ย่อยตามหัวข้อ)

1. `chore: rails new + ruby version + gitignore samples`
2. `chore: rspec, factory_bot, capybara, rubocop, brakeman`
3. `feat(thai): baht_text, thai date, money + specs`
4. `feat(models): workflow/reference/case models + migrations + validations`
5. `feat(seeds): workflow loader + ai_purchase_under_50k v1 + recommended list + fictional people`
6. `feat(services): eligibility evaluator + field computer + workflow search`
7. `feat(docs): prepare_template script + purchase_request.docx with MERGEFIELDs`
8. `feat(docs): DocumentGenerator + GenerateDocumentJob + golden test`
9. `feat(ui): design tokens + layout + base ViewComponents + home smoke page`
10. `chore: docker compose dev, bin/setup, .env.example, backup script`
11. `ci: github actions lint/security/test`
12. `docs: README, CLAUDE.md, ROADMAP, PROGRESS, OPEN_QUESTIONS`

## 10. เกณฑ์ว่า M0 เสร็จ

- `bin/setup && bin/rspec` ผ่านบนเครื่อง และ `docker compose up` เปิดหน้าแรกได้
- `bin/rubocop` และ `bin/brakeman` ไม่มี offense
- `rails db:seed` ซ้ำได้โดยไม่สร้างข้อมูลซ้ำ และเห็น workflow 1 รายการ 9 ขั้น + Recommended List 23 รายการ
- golden test ผ่าน และไฟล์จาก `rake docs:render_sample` เปิดใน Word ได้ (ตรวจด้วยตาโดยคุณ)
- CI เขียว (เมื่อมี repo บน GitHub — Q26)

## นอกขอบเขต M0

หน้าจอ wizard/ขั้นตอน/ฟอร์ม/ตรวจทานแบบเต็ม (M1), template รายงานผลการพิจารณา (M1 — ยังไม่มีไฟล์ .docx ต้นฉบับ มีแค่ PDF ❓), auth/roles (M2), ใบสำคัญจ่ายเงินยืม (M4)
