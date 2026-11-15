# CLAUDE.md

Procurement Workflow Assistant ("จัดซื้อง่าย") for PEA (กฟภ.) units. Users who don't know procurement
pick a workflow, see its steps, fill a case once, and get approval documents (.docx) that look like the
real forms. Domain details: `docs/DOMAIN.md`. Open questions: `docs/OPEN_QUESTIONS.md` (log uncertain
legal/regulatory points there instead of guessing).

## Stack

Ruby 3.4.12 (mise) · Rails 8.1 · SQLite everywhere (case data in a `json` column) · Solid Queue/Cache/Cable ·
Hotwire + importmap (no Node) · tailwindcss-rails v4 · ViewComponent · Sablon for .docx · Active Storage ·
RSpec + FactoryBot + Capybara · rubocop-rails-omakase · brakeman · GitHub Actions · Docker Compose (dev)

## Commands

The shell may not activate mise: prefix commands with `eval "$(mise env -s bash)" &&`.

```sh
bin/setup --skip-server        # deps, db:prepare, db:seed
bin/dev                        # web + tailwind watch + bin/jobs
bundle exec rspec              # all specs (golden .docx test included)
bin/rubocop -A                 # lint + autocorrect
bin/brakeman --no-pager        # security
bin/rails db:seed              # idempotent: reference data, docx templates, workflows
bin/rails docs:render_sample   # tmp/samples/<document>_sample.docx for every document
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
