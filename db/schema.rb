# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_15_150800) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "budget_sources", force: :cascade do |t|
    t.string "ref_doc_no", null: false
    t.date "ref_doc_date", null: false
    t.string "owner_unit", null: false
    t.string "budget_type", null: false
    t.integer "fiscal_year", null: false
    t.string "account_name", null: false
    t.string "account_code", null: false
    t.string "cost_center", null: false
    t.decimal "limit_amount", precision: 15, scale: 2
    t.string "limit_basis"
    t.date "spend_deadline"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ref_doc_no"], name: "index_budget_sources_on_ref_doc_no", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "parent_id"
    t.string "name", null: false
    t.string "code", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "code"], name: "index_departments_on_organization_id_and_code", unique: true
    t.index ["organization_id"], name: "index_departments_on_organization_id"
    t.index ["parent_id"], name: "index_departments_on_parent_id"
  end

  create_table "document_templates", force: :cascade do |t|
    t.string "code", null: false
    t.integer "version", null: false
    t.string "name", null: false
    t.text "description"
    t.string "template_path", null: false
    t.jsonb "field_keys", default: [], null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code", "version"], name: "index_document_templates_on_code_and_version", unique: true
  end

  create_table "field_definitions", force: :cascade do |t|
    t.bigint "workflow_template_id", null: false
    t.string "key", null: false
    t.string "label", null: false
    t.string "group_key", null: false
    t.integer "position", null: false
    t.string "field_type", null: false
    t.boolean "required", default: false, null: false
    t.text "help"
    t.text "example"
    t.text "why"
    t.jsonb "validation", default: {}, null: false
    t.jsonb "computed"
    t.jsonb "options", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_template_id", "key"], name: "index_field_definitions_on_workflow_template_id_and_key", unique: true
    t.index ["workflow_template_id"], name: "index_field_definitions_on_workflow_template_id"
  end

  create_table "generated_documents", force: :cascade do |t|
    t.bigint "procurement_case_id", null: false
    t.bigint "document_template_id", null: false
    t.integer "version", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "data_snapshot", default: {}, null: false
    t.text "error_message"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_template_id"], name: "index_generated_documents_on_document_template_id"
    t.index ["procurement_case_id", "document_template_id", "version"], name: "index_generated_documents_on_case_template_version", unique: true
    t.index ["procurement_case_id"], name: "index_generated_documents_on_procurement_case_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_organizations_on_code", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "title_prefix", null: false
    t.string "full_name", null: false
    t.string "position_short", null: false
    t.string "position_en"
    t.string "employee_code"
    t.string "unit_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_code"], name: "index_people_on_employee_code", unique: true
  end

  create_table "positions", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.string "short_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "title"], name: "index_positions_on_organization_id_and_title", unique: true
    t.index ["organization_id"], name: "index_positions_on_organization_id"
  end

  create_table "procurement_cases", force: :cascade do |t|
    t.bigint "workflow_template_id", null: false
    t.string "title", null: false
    t.string "status", default: "draft", null: false
    t.jsonb "data", default: {}, null: false
    t.string "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "department_id"
    t.bigint "created_by_user_id"
    t.index ["created_by_user_id"], name: "index_procurement_cases_on_created_by_user_id"
    t.index ["department_id"], name: "index_procurement_cases_on_department_id"
    t.index ["status"], name: "index_procurement_cases_on_status"
    t.index ["workflow_template_id"], name: "index_procurement_cases_on_workflow_template_id"
  end

  create_table "recommended_ais", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.text "capability"
    t.string "vendor", null: false
    t.string "list_version", null: false
    t.date "approved_on"
    t.boolean "highlighted", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "list_version"], name: "index_recommended_ais_on_name_and_list_version", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.bigint "department_id"
    t.bigint "position_id"
    t.bigint "person_id"
    t.string "roles", default: [], null: false, array: true
    t.boolean "active", default: true, null: false
    t.index ["department_id"], name: "index_users_on_department_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["person_id"], name: "index_users_on_person_id"
    t.index ["position_id"], name: "index_users_on_position_id"
    t.index ["roles"], name: "index_users_on_roles", using: :gin
  end

  create_table "workflow_documents", force: :cascade do |t|
    t.bigint "workflow_template_id", null: false
    t.bigint "document_template_id", null: false
    t.integer "step_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_template_id"], name: "index_workflow_documents_on_document_template_id"
    t.index ["workflow_template_id", "document_template_id"], name: "idx_on_workflow_template_id_document_template_id_46e94fafe8", unique: true
    t.index ["workflow_template_id"], name: "index_workflow_documents_on_workflow_template_id"
  end

  create_table "workflow_steps", force: :cascade do |t|
    t.bigint "workflow_template_id", null: false
    t.integer "position", null: false
    t.string "title", null: false
    t.text "description"
    t.string "actor_role"
    t.jsonb "output_documents", default: [], null: false
    t.jsonb "required_attachments", default: [], null: false
    t.text "tips"
    t.string "estimated_duration"
    t.boolean "confirmed", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_template_id", "position"], name: "index_workflow_steps_on_workflow_template_id_and_position", unique: true
    t.index ["workflow_template_id"], name: "index_workflow_steps_on_workflow_template_id"
  end

  create_table "workflow_templates", force: :cascade do |t|
    t.string "code", null: false
    t.integer "version", null: false
    t.string "name", null: false
    t.text "description"
    t.jsonb "keywords", default: [], null: false
    t.string "category"
    t.string "procurement_method"
    t.jsonb "legal_basis", default: [], null: false
    t.jsonb "eligibility_rules", default: [], null: false
    t.jsonb "field_groups", default: [], null: false
    t.jsonb "summary", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.string "source_digest"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code", "version"], name: "index_workflow_templates_on_code_and_version", unique: true
    t.index ["status"], name: "index_workflow_templates_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "departments", "departments", column: "parent_id"
  add_foreign_key "departments", "organizations"
  add_foreign_key "field_definitions", "workflow_templates"
  add_foreign_key "generated_documents", "document_templates"
  add_foreign_key "generated_documents", "procurement_cases"
  add_foreign_key "positions", "organizations"
  add_foreign_key "procurement_cases", "departments"
  add_foreign_key "procurement_cases", "users", column: "created_by_user_id"
  add_foreign_key "procurement_cases", "workflow_templates"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "people"
  add_foreign_key "users", "positions"
  add_foreign_key "workflow_documents", "document_templates"
  add_foreign_key "workflow_documents", "workflow_templates"
  add_foreign_key "workflow_steps", "workflow_templates"
end
