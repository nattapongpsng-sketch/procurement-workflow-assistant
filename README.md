# จัดซื้อง่าย — Procurement Workflow Assistant

เว็บแอปช่วยพนักงาน กฟภ. ที่ไม่รู้งานพัสดุ ให้ทำเรื่องจัดซื้อจัดจ้างได้ถูกต้อง:
ค้นหา workflow → เลือก workflow ที่เหมาะ → เห็นขั้นตอนทั้งหมด → สร้างเรื่องจาก template →
กรอกข้อมูลครั้งเดียว → ได้เอกสารเสนออนุมัติ (.docx) หน้าตาเหมือนแบบฟอร์มจริง

หน่วยงานตัวอย่าง: Thai Skill (สชก.(บก-ท)) · workflow แรก: จัดซื้อโปรแกรม AI วงเงินไม่เกิน 50,000 บาท (วิธีเฉพาะเจาะจง)

- ความเข้าใจงาน: [docs/DOMAIN.md](docs/DOMAIN.md)
- แผนและความคืบหน้า: [docs/ROADMAP.md](docs/ROADMAP.md) · [docs/PROGRESS.md](docs/PROGRESS.md) · [docs/M0_PLAN.md](docs/M0_PLAN.md)
- คำถามที่รอคำตอบ: [docs/OPEN_QUESTIONS.md](docs/OPEN_QUESTIONS.md)
- คู่มือสำหรับ Claude Code: [CLAUDE.md](CLAUDE.md)

## Stack

Ruby 3.4.12 · Rails 8.1 · SQLite (ทุก environment) · Solid Queue/Cache/Cable · Hotwire + importmap ·
tailwindcss-rails (v4) · ViewComponent · Sablon (.docx) · Active Storage · RSpec + FactoryBot + Capybara ·
rubocop-rails-omakase · brakeman · GitHub Actions · Docker

## รันบนเครื่อง

ต้องมี [mise](https://mise.jdx.dev) (หรือ Ruby 3.4.12 ตาม `.ruby-version`)

```sh
mise install            # ติดตั้ง Ruby ตาม mise.toml
bin/setup               # bundle, เตรียม DB, โหลด workflow/reference data แล้วเปิด bin/dev
# หรือ bin/setup --skip-server แล้วค่อย bin/dev
```

`bin/dev` เปิด 3 process: เว็บ (http://localhost:3000), Tailwind watcher และ Solid Queue worker (`bin/jobs`)

ถ้า shell ไม่โหลด mise อัตโนมัติ ให้รัน `eval "$(mise env -s bash)"` ก่อน

## รันด้วย Docker Compose

```sh
cp .env.example .env    # ไม่บังคับ
docker compose up --build
```

เปิด http://localhost:3000 — service `web` เตรียม DB และ seed ให้เอง, `css` build Tailwind, `jobs` รัน Solid Queue
ไฟล์ SQLite และไฟล์ Active Storage อยู่ใน volume `storage` (ไม่หายเมื่อ rebuild)

## ทดสอบและตรวจคุณภาพ

```sh
bundle exec rspec          # ทั้งหมด รวม golden test ของเอกสาร .docx และ system spec
bin/rubocop                # style
bin/brakeman --no-pager    # security static analysis
bin/bundler-audit          # gem ที่มีช่องโหว่
```

CI (`.github/workflows/ci.yml`) รัน brakeman, bundler-audit, importmap audit, rubocop และ RSpec ทุก push/PR

## เอกสาร .docx

- template อยู่ที่ `app/templates/docx/` (มี MERGEFIELD ของ Sablon) และเป็น source of truth ของหน้าตาเอกสาร
- สร้างไฟล์ตัวอย่างไปเปิดใน Word: `bin/rails docs:render_sample` → `tmp/samples/<เอกสาร>_sample.docx` ทุกเอกสาร
- สร้าง template ใหม่จากแบบฟอร์มจริง: `bundle exec ruby script/docx/prepare_purchase_request.rb`
  (ต้องมีไฟล์ต้นฉบับใน `docs/samples/` ซึ่งไม่อยู่ใน git เพราะมีข้อมูลบุคคลจริง)
- รายงานผลการพิจารณาไม่มี .docx ต้นฉบับ สร้างจาก template รายงานขอซื้อ + ถ้อยคำใน PDF: `bundle exec ruby script/docx/build_result_report.rb`
- ถ้าเปลี่ยน template หรือข้อมูลตัวอย่างโดยตั้งใจ: `UPDATE_GOLDEN=1 bundle exec rspec spec/services/document_generator_spec.rb`
  แล้วตรวจ diff ของ `spec/fixtures/golden/purchase_request.txt` ก่อน commit

## เพิ่ม workflow ใหม่ (ไม่ต้องแก้โค้ด)

1. สร้าง `db/seeds/workflows/<code>.v1.yml` (ดูตัวอย่าง `ai_purchase_under_50k.v1.yml`)
2. ถ้ามีเอกสารใหม่ ใส่ .docx ใน `app/templates/docx/` และเพิ่มใน `db/seeds/documents.yml`
3. `bin/rails db:seed` — loader ตรวจ group, สูตร และ rule ให้ ถ้าผิดจะบอกว่าผิดตรงไหน

workflow ที่ `published` แล้วแก้ไม่ได้ ถ้าต้องเปลี่ยน ให้สร้างไฟล์ `v2` (เรื่องเดิมยังผูกกับ v1)

## สำรองข้อมูล

```sh
script/backup_sqlite      # backup ทุก DB ใน storage/ (SQLite backup API + integrity check) และไฟล์ Active Storage
```

ตั้ง cron เช่น `0 2 * * * cd /rails && script/backup_sqlite >> log/backup.log 2>&1` และคัดลอก `BACKUP_DIR`
ออกนอกเครื่อง หรือใช้ [Litestream](https://litestream.io) replicate ต่อเนื่อง

## ข้อมูลส่วนบุคคล

- `docs/samples/` (เอกสารจริง) ไม่อยู่ใน git
- seed และ fixture ใช้ชื่อสมมติเท่านั้น (`db/seeds/reference/people.yml`)
