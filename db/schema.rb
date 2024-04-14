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

ActiveRecord::Schema[7.1].define(version: 2024_04_14_195437) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "document_analytics", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "group_id", null: false
    t.bigint "document_id", null: false
    t.integer "version_number"
    t.integer "action_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "counter_party_ip"
    t.string "counter_party_user_agent"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "owner", default: 0
    t.integer "version_number"
    t.bigint "project_id", null: false
    t.string "counter_party_full_name"
    t.string "counter_party_email"
    t.datetime "counter_party_date"
    t.string "counter_party_ip"
    t.string "counter_party_user_agent"
    t.string "party_full_name"
    t.string "party_email"
    t.datetime "party_date"
    t.string "party_ip"
    t.string "party_user_agent"
    t.integer "number_of_pages"
    t.integer "group_status_at_creation"
    t.bigint "creator_id"
    t.index ["creator_id"], name: "index_documents_on_creator_id"
    t.index ["group_id"], name: "index_documents_on_group_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.integer "status", default: 1
    t.bigint "user_id"
    t.bigint "project_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.bigint "last_document_id"
    t.string "job_id"
    t.integer "job_status", default: 0
    t.index ["code"], name: "index_groups_on_code"
    t.index ["last_document_id"], name: "index_groups_on_last_document_id"
    t.index ["project_id", "name", "status"], name: "index_groups_on_project_id_and_name_and_status"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
  end

  create_table "project_users", force: :cascade do |t|
    t.bigint "project_id"
    t.bigint "user_id"
    t.boolean "admin", default: false
    t.datetime "last_viewed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "access", default: false
    t.bigint "group_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_date", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "end_date"
    t.integer "party_count", default: 0
    t.integer "counter_party_count", default: 0
    t.string "code"
    t.bigint "authorized_agent_of_signatory_user_id"
    t.index ["code"], name: "index_projects_on_code"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "timezone", default: "Eastern Time (US & Canada)"
    t.string "first_name"
    t.string "last_name"
    t.string "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_login"
    t.index ["email"], name: "index_users_on_email"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.string "ip_address"
    t.string "user_agent"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "documents", "groups"
  add_foreign_key "documents", "projects"
  add_foreign_key "documents", "users", column: "creator_id"
end
