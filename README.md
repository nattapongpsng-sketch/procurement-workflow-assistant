# จัดซื้อง่าย — Procurement Workflow Assistant

ระบบจัดซื้อจัดจ้างวิธีเฉพาะเจาะจงวงเงินไม่เกิน 100,000 บาท และเบิกจ่ายตรง (เช่น ค่าสาธารณูปโภค)
สำหรับหน่วยงานใน กฟภ.: กรอกข้อมูลครั้งเดียว ได้เอกสารครบชุดตามแบบฟอร์มจริง (PDF + .docx)
แล้วส่งอนุมัติ ตรวจรับ และเบิกจ่ายต่อเป็นลำดับขั้น

- ความต้องการ: [docs/Requirement.md](docs/Requirement.md) · แผน: [docs/REPLAN.md](docs/REPLAN.md), [docs/ROADMAP.md](docs/ROADMAP.md) · ความคืบหน้า: [docs/PROGRESS.md](docs/PROGRESS.md)
- ความรู้งานพัสดุ: [docs/DOMAIN.md](docs/DOMAIN.md) · คำถามที่รอคำตอบ: [docs/OPEN_QUESTIONS.md](docs/OPEN_QUESTIONS.md)
- คู่มือสำหรับ Claude Code: [CLAUDE.md](CLAUDE.md) · Milestones: GitHub → Milestones

## Stack

Ruby 3.4.12 · Rails 8.1 · PostgreSQL 17 · Solid Queue/Cache/Cable · Hotwire + importmap · tailwindcss-rails (v4) ·
ViewComponent · Sablon (.docx) + LibreOffice headless (PDF ฝังฟอนต์ TH Sarabun New) · Active Storage ·
RSpec + FactoryBot + Capybara · rubocop-rails-omakase · brakeman · GitHub Actions · Docker

## รันด้วย Docker Compose (แนะนำ)

```sh
cp .env.example .env      # ไม่บังคับ
docker compose up --build
```

เปิด http://localhost:3000 แล้วเข้าสู่ระบบด้วยผู้ใช้ตัวอย่าง (ชื่อสมมติ, มีเฉพาะ development) เช่น
`admin@example.com` รหัสผ่าน `dev-password-1234` — มีผู้ใช้ครบทุกบทบาทใน [db/seeds/development_users.yml](db/seeds/development_users.yml)

Service: `db` (PostgreSQL, ข้อมูลใน volume `pgdata`), `web` (เตรียม DB + seed ให้เอง), `css` (Tailwind), `jobs` (Solid Queue)
ไฟล์แนบและเอกสารที่สร้างอยู่ใน `./storage` · container รันด้วย uid/gid ของคุณ (ตั้ง `UID`/`GID` ได้) ไฟล์จึงไม่เป็นของ root

## รันบนเครื่อง (Rails บนเครื่อง, PostgreSQL ใน Docker)

ต้องมี [mise](https://mise.jdx.dev) (หรือ Ruby 3.4.12) และ Docker

```sh
mise install
docker compose up -d db
bin/setup                 # bundle, เตรียม DB, seed แล้วเปิด bin/dev (web + Tailwind + jobs)
```

ถ้า shell ไม่โหลด mise อัตโนมัติ ให้รัน `eval "$(mise env -s bash)"` ก่อน
บนเครื่องไม่มี LibreOffice: ระบบยังสร้าง .docx ได้ ส่วน PDF สร้างใน Docker และ CI (spec ส่วน PDF จะถูกข้าม)

## ทดสอบและตรวจคุณภาพ

```sh
bundle exec rspec          # ทั้งหมด (golden test ของเอกสาร, audit log, ภาษี, system spec)
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/services/pdf_converter_spec.rb   # PDF
bin/rubocop                # style
bin/brakeman --no-pager    # security
bin/bundler-audit          # gem ที่มีช่องโหว่
```

CI (`.github/workflows/ci.yml`): brakeman, bundler-audit, importmap audit, rubocop และ RSpec บน PostgreSQL
พร้อม LibreOffice + TH Sarabun New (spec PDF ต้องผ่าน ไม่ข้าม)

## ผู้ใช้และสิทธิ์

- 8 บทบาทตาม Requirement (ผู้ขอซื้อ, เจ้าหน้าที่พัสดุ, หัวหน้าเจ้าหน้าที่, ผู้มีอำนาจอนุมัติ, ผู้ตรวจรับ, การเงิน, Admin, ผู้ตรวจสอบ) — ผู้ใช้ 1 คนมีได้หลายบทบาท
- Admin จัดการผู้ใช้ ส่วนงาน ตำแหน่งที่เมนู **ตั้งค่า** · ผู้ตรวจสอบและ Admin ดู **ประวัติการใช้งาน** (audit log ที่แก้/ลบไม่ได้)
- Admin คนแรกใน production: `bin/rails users:create_admin EMAIL=... NAME=...` (แสดงรหัสผ่านชั่วคราวครั้งเดียว)

## เอกสาร (.docx → PDF)

- template อยู่ที่ `app/templates/docx/` (มี MERGEFIELD ของ Sablon) และเป็น source of truth ของหน้าตาเอกสาร
- PDF แปลงจาก .docx ด้วย LibreOffice (ฟอนต์ TH Sarabun New ติดตั้งด้วย `script/install_th_sarabun_new` — GPL v2+ พร้อม font exception ฝังใน PDF ได้)
- ไฟล์ตัวอย่าง: `bin/rails docs:render_sample` → `tmp/samples/<เอกสาร>_sample.docx`
- สร้าง template ใหม่: `bundle exec ruby script/docx/prepare_purchase_request.rb` (ต้องมีต้นฉบับใน `docs/samples/` ซึ่งไม่อยู่ใน git) และ `bundle exec ruby script/docx/build_result_report.rb`
- เปลี่ยน template หรือข้อมูลตัวอย่างโดยตั้งใจ: `UPDATE_GOLDEN=1 bundle exec rspec spec/services/document_generator_spec.rb spec/services/result_report_spec.rb` แล้วตรวจ diff ก่อน commit

## เพิ่ม workflow ใหม่ (ไม่ต้องแก้โค้ด)

1. สร้าง `db/seeds/workflows/<code>.v1.yml` (ดูตัวอย่าง `ai_purchase_under_50k.v2.yml`)
2. ถ้ามีเอกสารใหม่ ใส่ .docx ใน `app/templates/docx/` และเพิ่มใน `db/seeds/documents.yml`
3. `bin/rails db:seed` — loader ตรวจ group, สูตร และ rule ให้

workflow ที่ `published` แล้วแก้ไม่ได้ ถ้าต้องเปลี่ยนให้สร้างเวอร์ชันถัดไป (เรื่องเดิมยังผูกกับเวอร์ชันเดิม)

## สำรองข้อมูล

```sh
script/backup_db          # pg_dump ทุกฐานข้อมูลของแอป + ไฟล์ Active Storage, ลบชุดที่เก่ากว่า BACKUP_KEEP_DAYS
```

ตั้ง cron เช่น `0 2 * * * cd /rails && script/backup_db >> log/backup.log 2>&1` และคัดลอก `BACKUP_DIR` ออกนอกเครื่อง
(NFR-07: สำรองทุกวัน)

## ข้อมูลส่วนบุคคล

- `docs/samples/` (เอกสารจริง) ไม่อยู่ใน git
- seed และ fixture ใช้ชื่อสมมติเท่านั้น
