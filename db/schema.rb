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

ActiveRecord::Schema[8.0].define(version: 2025_10_16_051842) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "grants", force: :cascade do |t|
    t.string "funder_name", null: false
    t.string "grant_name", null: false
    t.string "status", null: false
    t.string "project_name", null: false
    t.integer "fiscal_year", null: false
    t.date "deadline"
    t.date "submission_date"
    t.date "date_awarded_declined"
    t.date "award_start_date"
    t.date "award_end_date"
    t.date "date_notified"
    t.decimal "amount_requested", precision: 10, scale: 2
    t.decimal "amount_awarded", precision: 10, scale: 2
    t.text "upcoming_tasks"
    t.string "portal_website"
    t.string "portal_username"
    t.string "portal_password"
    t.string "funder_location"
    t.text "funder_contact_info"
    t.string "funder_type"
    t.text "opportunity_notes"
    t.text "funder_notes"
    t.string "grant_owner"
    t.bigint "import_batch_id"
    t.integer "row_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fiscal_year"], name: "index_grants_on_fiscal_year"
    t.index ["funder_name"], name: "index_grants_on_funder_name"
    t.index ["import_batch_id"], name: "index_grants_on_import_batch_id"
    t.index ["status"], name: "index_grants_on_status"
  end

  create_table "import_batches", force: :cascade do |t|
    t.string "filename"
    t.string "status", default: "pending"
    t.integer "total_rows"
    t.integer "successful_rows", default: 0
    t.integer "failed_rows", default: 0
    t.jsonb "error_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_import_batches_on_status"
  end

  add_foreign_key "grants", "import_batches"
end
