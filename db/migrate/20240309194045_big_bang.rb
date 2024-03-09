class BigBang < ActiveRecord::Migration[7.1]
  def change
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

    create_table "pg_search_documents", force: :cascade do |t|
      t.text "content"
      t.string "searchable_type"
      t.bigint "searchable_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
    end
  
    create_table "project_users", force: :cascade do |t|
      t.integer "project_id"
      t.integer "user_id"
      t.boolean "admin", default: false
      t.datetime "last_viewed_at", precision: nil
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "access", default: false
    end
  
    create_table "projects", force: :cascade do |t|
      t.string "name"
      t.text "description"
      t.integer "user_id"
      t.integer "status", default: 0
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
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
  
    add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
    add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  end
end
