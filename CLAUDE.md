# CLAUDE.md

Procurement Workflow Assistant ("จัดซื้อง่าย"): specific-method procurement ≤ 100,000 baht and direct
payments (utilities) for a PEA (กฟภ.) unit — fill a request once, get every document (PDF + .docx) in the
unit's real forms, route it for approval, inspection and payment. **Requirements: `docs/Requirement.md`**
(FR-xx / NFR-xx codes), plan: `docs/REPLAN.md`, `docs/ROADMAP.md`. Domain: `docs/DOMAIN.md`. Open
questions: `docs/OPEN_QUESTIONS.md` (log uncertain legal/regulatory/tax points there instead of guessing).

## Stack

Ruby 3.4.12 (mise) · Rails 8.1 · PostgreSQL 17 (case data in `jsonb`; Solid Queue/Cache/Cable on Postgres) ·
Rails 8 authentication · Hotwire + importmap (no Node) · tailwindcss-rails v4 · ViewComponent · Sablon (.docx)
+ LibreOffice headless (PDF, TH Sarabun New embedded) · Active Storage · fx (DB triggers in schema.rb) ·
RSpec + FactoryBot + Capybara · rubocop-rails-omakase · brakeman · GitHub + GitHub Actions (Requirement says
GitLab; owner chose GitHub) · Docker Compose (dev)

## Commands

The shell may not activate mise: prefix commands with `eval "$(mise env -s bash)" &&`.
PostgreSQL runs in Docker: `docker compose up -d db` (host port 5432, postgres/postgres).
LibreOffice is only in the Docker image and CI — locally PDF specs skip; run them with
`docker compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/services/pdf_converter_spec.rb`.

```sh
docker compose up -d db        # PostgreSQL for host-side Rails
bin/setup --skip-server        # deps, db:prepare, db:seed (+ fictional dev users, password dev-password-1234)
docker compose up              # full stack: db, web, css, jobs (runs as your uid)
bin/dev                        # web + tailwind watch + bin/jobs
bundle exec rspec              # all specs (golden .docx test included)
bin/rubocop -A                 # lint + autocorrect
bin/brakeman --no-pager        # security
bin/rails db:seed              # idempotent: reference data, docx templates, workflows
bin/rails docs:render_sample   # tmp/samples/<document>_sample.docx for every document
bin/rails users:create_admin EMAIL=... NAME=...   # first admin (prints a one-time password)
script/backup_db               # pg_dump of every app database + Active Storage files
UPDATE_GOLDEN=1 bundle exec rspec spec/services/document_generator_spec.rb   # then review the diff
bundle exec ruby script/docx/prepare_purchase_request.rb                       # rebuild template (needs docs/samples)
bundle exec ruby script/docx/build_result_report.rb                            # rebuild result report (from the purchase request template)
```

## Design principles (must hold)

1. **Workflows are data, not code** — YAML in `db/seeds/workflows/*.vN.yml`, versioned. A published version
   is frozen (model validation + loader refuse changes); change = new version file. Cases bind to a version.
2. **Enter once, use in every document** — all values live in `ProcurementCase#data`, flat by
   `FieldDefinition#key` (dotted, e.g. `price.unit_price`). Documents read only from there.
3. **Computed values are never typed** — `FieldComputer` derives them from a whitelist of functions
   (`multiply`, `baht_text`, `thai_date`, `doc_number`, …; no eval). `ProcurementCase` rejects stored computed keys.
4. **Eligibility is declarative** — `eligibility_rules` in YAML, evaluated by `EligibilityEvaluator`;
   every rule has `fail.reason` and `alternatives`. Missing data → `unknown`, not fail.
5. **The real .docx is the source of truth for layout** — templates in `app/templates/docx/` are the real
   forms with MERGEFIELDs inserted by `script/docx/*`; never build layouts from scratch.
   Only exception: `result_report.docx` (no original .docx exists, owner-approved, Q28) is rebuilt from the
   purchase request template + the PDF wording.
6. **Every text is for non-experts** — every input field needs `help`, `example`, `why`
   (validated in `FieldDefinition`). UI language: Thai.

## Conventions

- Roles (`User::ROLES`, several per user): requester, procurement_officer, procurement_head, approver,
  inspector, finance, admin, auditor. Controllers: `require_role :admin`. Users see their own department's
  cases; admin and auditor see all (NFR-05). Separation of duties is checked where the duty happens.
- Every domain/reference model `include Auditable` (FR-28): audit rows are written in the same transaction;
  `audit_events` is append-only, enforced by PostgreSQL triggers (`db/functions`, `db/triggers`, fx gem).
  Domain actions (approve, return…) call `AuditEvent.record`.
- Money and tax go through `TaxCalculator` (VAT once on the total, satang half-up; withholding on the base
  before VAT; rates in `withholding_tax_types`). Never hand-roll VAT.
- Generated documents: `.docx` via Sablon, then PDF via `PdfConverter` (required in production).

- The case model is `ProcurementCase` (`case` is a Ruby keyword); UI calls it "เรื่อง".
- Services in `app/services`, plain Ruby, one public `call`. Thai helpers in `lib/thai` (`Thai.baht_text`,
  `Thai.money` → `7,990.-`, `Thai.date(d)` / `Thai.date(d, format: :short)`, `Thai.doc_number`).
- Money: `BigDecimal` / decimal strings, never floats. Prices are entered as charged (no automatic VAT, Q14).
- Document font: TH Sarabun New (Requirement NFR-04, Q22); `script/docx` renames it in every template.
- Reference fields (`reference`, `person`, `list` of person) store ids; `DocumentContext` expands them
  (e.g. `budget.source.charge_text`, `people.inspectors.text`) for templates.
- File fields store an Active Storage blob `signed_id`; attachments hang off `ProcurementCase#attachments`.
- Template fields must map to a workflow key or a reference sub-path — `spec/services/seed_loader_spec.rb` checks it.
- UI: ViewComponents in `app/components`, design tokens in `app/assets/tailwind/application.css`
  (from the UI canvas; design system "ชวนกิน"). Use token classes (`bg-primary`, `text-text-2`, `rounded-card`).
- Tests: RSpec only. System specs use rack_test; tag `js: true` for headless Chrome.
- Small commits per topic; end messages with the attribution line from the session.

## Privacy

- `docs/samples/` holds real documents (names, employee IDs, signatures) — gitignored; never copy real
  names into code, seeds, fixtures, templates or docs. Use the fictional people in `db/seeds/reference/people.yml`.
- `script/docx/*` matches paragraphs by pattern, not by real names, and scrubs docProps.

## Domain terms (short)

| Term | Meaning |
|---|---|
| รายงานขอซื้อขอจ้าง | approval request to start a purchase (sections 1–7 + 8 ข้อเสนออื่น ๆ) |
| รายงานผลการพิจารณาและอนุมัติสั่งซื้อ | result report asking to approve the order |
| วิธีเฉพาะเจาะจง | specific method, ม.56(2)(ข), ระเบียบฯ ข้อ 79, ≤ 500,000 บาท |
| ราคากลาง / สืบราคา | reference price / price survey (screenshot + date = เอกสารแนบ 3) |
| Recommended List | 23 AI products PEA allows (อนุมัติ ผวก. 8 เม.ย. 2569); > 50,000 บาท needs committee approval |
| ผู้ตรวจรับพัสดุ | inspector appointed in the purchase request (8.2) |
| ผู้ยืมเงิน / ใบสำคัญจ่ายเงินยืม | employee who borrows cash from กกง. to pay; loan voucher (M4) |
| ผชก. | approver in the sample unit (Thai Skill Business Unit Head) |
