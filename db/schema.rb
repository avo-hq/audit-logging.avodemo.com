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

ActiveRecord::Schema[7.2].define(version: 2026_11_11_120000) do
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

  create_table "avo_ai_chats", force: :cascade do |t|
    t.integer "ruby_llm_model_id"
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.string "name"
    t.json "attached_context"
    t.boolean "cancelled", default: false, null: false
    t.datetime "responding_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ruby_llm_model_id"], name: "index_avo_ai_chats_on_ruby_llm_model_id"
    t.index ["user_type", "user_id"], name: "index_avo_ai_chats_on_user"
  end

  create_table "avo_ai_connector_grants", force: :cascade do |t|
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.integer "connector_tool_id", null: false
    t.string "digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["connector_tool_id"], name: "index_avo_ai_connector_grants_on_connector_tool_id"
    t.index ["user_type", "user_id", "connector_tool_id"], name: "index_avo_ai_connector_grants_on_user_and_tool", unique: true
    t.index ["user_type", "user_id"], name: "index_avo_ai_connector_grants_on_user"
  end

  create_table "avo_ai_connector_tools", force: :cascade do |t|
    t.integer "connector_id", null: false
    t.string "name", null: false
    t.text "description"
    t.json "argument_schema", default: {}, null: false
    t.string "digest", null: false
    t.string "policy", default: "on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["connector_id", "name"], name: "index_avo_ai_connector_tools_on_connector_id_and_name", unique: true
    t.index ["connector_id"], name: "index_avo_ai_connector_tools_on_connector_id"
  end

  create_table "avo_ai_connectors", force: :cascade do |t|
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.string "server_url", null: false
    t.string "name"
    t.string "audience", default: "private", null: false
    t.string "auth_kind", default: "none", null: false
    t.string "status", default: "pending", null: false
    t.text "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_type", "user_id"], name: "index_avo_ai_connectors_on_user"
  end

  create_table "avo_ai_feedbacks", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.integer "message_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.string "vote", null: false
    t.string "reason"
    t.text "comment"
    t.string "status", default: "open", null: false
    t.text "admin_note"
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_avo_ai_feedbacks_on_chat_id"
    t.index ["message_id"], name: "index_avo_ai_feedbacks_on_message_id"
    t.index ["status"], name: "index_avo_ai_feedbacks_on_status"
    t.index ["user_type", "user_id"], name: "index_avo_ai_feedbacks_on_user"
    t.index ["vote"], name: "index_avo_ai_feedbacks_on_vote"
  end

  create_table "avo_ai_messages", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.string "role", null: false
    t.text "content"
    t.boolean "cache_until_here", default: false, null: false
    t.text "thinking_text"
    t.text "thinking_signature"
    t.json "citations"
    t.json "server_tool_calls"
    t.json "raw_content"
    t.json "raw_reasoning"
    t.string "finish_reason"
    t.json "meta"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_avo_ai_messages_on_chat_id"
  end

  create_table "avo_ai_pending_writes", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.string "action", null: false
    t.string "status", default: "pending", null: false
    t.string "resource"
    t.string "record_type"
    t.string "record_id"
    t.json "payload", default: {}, null: false
    t.integer "ruby_llm_tool_call_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "status"], name: "index_avo_ai_pending_writes_on_chat_id_and_status"
    t.index ["chat_id"], name: "index_avo_ai_pending_writes_on_chat_id"
    t.index ["ruby_llm_tool_call_id"], name: "index_avo_ai_pending_writes_on_ruby_llm_tool_call_id", unique: true
    t.index ["user_type", "user_id"], name: "index_avo_ai_pending_writes_on_user"
  end

  create_table "avo_ai_skills", force: :cascade do |t|
    t.string "title", null: false
    t.string "description"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_avo_ai_skills_on_title", unique: true
  end

  create_table "avo_ai_write_logs", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.string "resource", null: false
    t.string "record_type", null: false
    t.string "record_id", null: false
    t.string "action", null: false
    t.json "before_snapshot"
    t.json "after_snapshot"
    t.datetime "reverted_at"
    t.bigint "pending_write_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "created_at"], name: "index_avo_ai_write_logs_on_chat_id_and_created_at"
    t.index ["chat_id"], name: "index_avo_ai_write_logs_on_chat_id"
    t.index ["pending_write_id"], name: "index_avo_ai_write_logs_on_pending_write_id"
    t.index ["user_type", "user_id"], name: "index_avo_ai_write_logs_on_user"
  end

  create_table "avo_api_tokens", force: :cascade do |t|
    t.string "name", null: false
    t.string "token_digest", null: false
    t.string "display_prefix", null: false
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.datetime "last_used_at"
    t.json "entitlements"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_avo_api_tokens_on_owner_type_and_owner_id"
    t.index ["token_digest"], name: "index_avo_api_tokens_on_token_digest", unique: true
  end

  create_table "avo_audit_logging_activities", force: :cascade do |t|
    t.string "activity_class"
    t.string "action"
    t.bigint "author_id"
    t.string "author_type"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "origin"
    t.string "origin_record_type"
    t.integer "origin_record_id"
    t.index ["origin"], name: "index_avo_audit_logging_activities_on_origin"
    t.index ["origin_record_type", "origin_record_id"], name: "index_avo_audit_logging_activities_on_origin_record"
  end

  create_table "avo_audit_logging_activity_pivots", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.string "activity_pivot_type"
    t.integer "activity_pivot_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "targeted", default: false, null: false
    t.index ["activity_id"], name: "index_avo_audit_logging_activity_pivots_on_activity_id"
    t.index ["activity_pivot_type", "activity_pivot_id"], name: "index_avo_audit_logging_activity_pivots_on_activity_pivot"
    t.index ["record_type", "record_id"], name: "index_avo_audit_logging_activity_pivots_on_record"
  end

  create_table "avo_mcp_server_access_grants", force: :cascade do |t|
    t.integer "connection_id", null: false
    t.string "code_digest", null: false
    t.json "capabilities", default: [], null: false
    t.string "code_challenge", null: false
    t.string "code_challenge_method", default: "S256", null: false
    t.string "redirect_uri", null: false
    t.string "client_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "redeemed_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_digest"], name: "index_avo_mcp_server_access_grants_on_code_digest", unique: true
    t.index ["connection_id"], name: "index_avo_mcp_server_access_grants_on_connection_id"
    t.index ["expires_at"], name: "index_avo_mcp_server_access_grants_on_expires_at"
  end

  create_table "avo_mcp_server_access_tokens", force: :cascade do |t|
    t.integer "connection_id", null: false
    t.string "access_token_digest", null: false
    t.string "refresh_token_digest", null: false
    t.string "family_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "refresh_expires_at", null: false
    t.datetime "rotated_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token_digest"], name: "index_avo_mcp_server_access_tokens_on_access_token_digest", unique: true
    t.index ["connection_id"], name: "index_avo_mcp_server_access_tokens_on_connection_id"
    t.index ["family_id"], name: "index_avo_mcp_server_access_tokens_on_family_id"
    t.index ["refresh_token_digest"], name: "index_avo_mcp_server_access_tokens_on_refresh_token_digest", unique: true
  end

  create_table "avo_mcp_server_clients", force: :cascade do |t|
    t.string "issuer", null: false
    t.string "client_id", null: false
    t.string "client_name"
    t.string "application_type"
    t.json "redirect_uris", default: [], null: false
    t.string "client_secret_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issuer", "client_id"], name: "index_avo_mcp_server_clients_on_issuer_and_client_id", unique: true
  end

  create_table "avo_mcp_server_connections", force: :cascade do |t|
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.string "client_id", null: false
    t.string "client_name"
    t.string "slug"
    t.json "capabilities", default: [], null: false
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_avo_mcp_server_connections_on_client_id"
    t.index ["revoked_at"], name: "index_avo_mcp_server_connections_on_revoked_at"
    t.index ["slug"], name: "index_avo_mcp_server_connections_on_slug", unique: true
    t.index ["user_type", "user_id"], name: "index_avo_mcp_server_connections_on_user"
  end

  create_table "avo_mcp_server_events", force: :cascade do |t|
    t.integer "connection_id", null: false
    t.string "rpc_method", null: false
    t.string "tool_name"
    t.string "resource_name"
    t.string "outcome", null: false
    t.integer "error_code"
    t.text "error_message"
    t.json "arguments"
    t.integer "duration_ms"
    t.datetime "created_at", null: false
    t.index ["connection_id", "id"], name: "index_avo_mcp_server_events_on_connection_id_and_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.text "description", null: false
    t.integer "quantity", null: false
    t.string "manufacturer", null: false
    t.integer "category", null: false
    t.boolean "is_featured", default: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "warehouse_id"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "supplier_id"
    t.string "sku"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
    t.index ["user_id"], name: "index_products_on_user_id"
    t.index ["warehouse_id"], name: "index_products_on_warehouse_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string "number", null: false
    t.integer "supplier_id", null: false
    t.integer "warehouse_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.integer "status", default: 0, null: false
    t.date "expected_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_orders_on_product_id"
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
    t.index ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id"
  end

  create_table "ruby_llm_batches", force: :cascade do |t|
    t.string "provider_batch_id", null: false
    t.string "provider", null: false
    t.string "status", null: false
    t.string "raw_status"
    t.boolean "completed", default: false, null: false
    t.string "chat_type"
    t.string "batch_protocol"
    t.json "chat_ids", default: []
    t.json "request_counts"
    t.json "reported_cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_batch_id"], name: "index_ruby_llm_batches_on_provider_and_provider_batch_id", unique: true
    t.index ["status"], name: "index_ruby_llm_batches_on_status"
  end

  create_table "ruby_llm_mcp_credentials", force: :cascade do |t|
    t.string "owner_type"
    t.integer "owner_id"
    t.string "key", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_ruby_llm_mcp_credentials_on_key", unique: true
    t.index ["owner_type", "owner_id"], name: "index_ruby_llm_mcp_credentials_on_owner"
  end

  create_table "ruby_llm_models", force: :cascade do |t|
    t.string "model_id", null: false
    t.string "name", null: false
    t.string "provider", null: false
    t.string "family"
    t.datetime "model_created_at"
    t.integer "context_window"
    t.integer "max_output_tokens"
    t.date "knowledge_cutoff"
    t.datetime "unlisted_at"
    t.json "modalities", default: {}
    t.json "capabilities", default: []
    t.json "pricing", default: {}
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["capabilities"], name: "index_ruby_llm_models_on_capabilities"
    t.index ["family"], name: "index_ruby_llm_models_on_family"
    t.index ["modalities"], name: "index_ruby_llm_models_on_modalities"
    t.index ["provider", "model_id"], name: "index_ruby_llm_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_ruby_llm_models_on_provider"
  end

  create_table "ruby_llm_tool_calls", force: :cascade do |t|
    t.string "message_type", null: false
    t.integer "message_id", null: false
    t.string "result_type"
    t.integer "result_id"
    t.string "tool_call_id", null: false
    t.string "name", null: false
    t.text "thought_signature"
    t.string "approval"
    t.boolean "remote", default: false, null: false
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "pending_input"
    t.index ["message_type", "message_id"], name: "index_ruby_llm_tool_calls_on_message_type_and_message_id"
    t.index ["name"], name: "index_ruby_llm_tool_calls_on_name"
    t.index ["result_type", "result_id"], name: "index_ruby_llm_tool_calls_on_result_type_and_result_id"
    t.index ["tool_call_id"], name: "index_ruby_llm_tool_calls_on_tool_call_id", unique: true
  end

  create_table "ruby_llm_usages", force: :cascade do |t|
    t.string "chat_type", null: false
    t.integer "chat_id", null: false
    t.string "message_type"
    t.integer "message_id"
    t.string "operation", null: false
    t.string "provider", null: false
    t.string "model", null: false
    t.string "status", null: false
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.integer "cache_read_tokens"
    t.integer "cache_write_tokens"
    t.integer "thinking_tokens"
    t.decimal "input_cost", precision: 16, scale: 10
    t.decimal "output_cost", precision: 16, scale: 10
    t.decimal "cache_read_cost", precision: 16, scale: 10
    t.decimal "cache_write_cost", precision: 16, scale: 10
    t.decimal "thinking_cost", precision: 16, scale: 10
    t.decimal "total_cost", precision: 16, scale: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_type", "chat_id"], name: "index_ruby_llm_usages_on_chat_type_and_chat_id"
    t.index ["message_type", "message_id"], name: "index_ruby_llm_usages_on_message_type_and_message_id"
    t.index ["status"], name: "index_ruby_llm_usages_on_status"
    t.check_constraint "operation IN ('chat', 'embedding', 'moderation', 'image', 'speech', 'transcription', 'ocr', 'rerank')"
    t.check_constraint "status IN ('pending', 'succeeded', 'failed', 'cancelled')"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "reference", null: false
    t.integer "warehouse_id", null: false
    t.string "carrier", null: false
    t.string "tracking_number"
    t.string "destination", null: false
    t.integer "status", default: 0, null: false
    t.datetime "shipped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["warehouse_id"], name: "index_shipments_on_warehouse_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "warehouse_id"
    t.integer "kind", null: false
    t.integer "quantity", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["warehouse_id"], name: "index_stock_movements_on_warehouse_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_email"
    t.string "country"
    t.integer "lead_time_days", default: 7, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.json "roles"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object", limit: 1073741823
    t.text "object_changes", limit: 1073741823
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inventory_value_cents", default: 0, null: false
    t.string "inventory_value_currency", default: "USD", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "avo_ai_chats", "ruby_llm_models"
  add_foreign_key "avo_ai_connector_grants", "avo_ai_connector_tools", column: "connector_tool_id"
  add_foreign_key "avo_ai_connector_tools", "avo_ai_connectors", column: "connector_id"
  add_foreign_key "avo_ai_feedbacks", "avo_ai_chats", column: "chat_id", on_delete: :cascade
  add_foreign_key "avo_ai_feedbacks", "avo_ai_messages", column: "message_id", on_delete: :cascade
  add_foreign_key "avo_ai_messages", "avo_ai_chats", column: "chat_id"
  add_foreign_key "avo_ai_pending_writes", "avo_ai_chats", column: "chat_id"
  add_foreign_key "avo_ai_pending_writes", "ruby_llm_tool_calls", on_delete: :nullify
  add_foreign_key "avo_ai_write_logs", "avo_ai_chats", column: "chat_id"
  add_foreign_key "avo_mcp_server_access_grants", "avo_mcp_server_connections", column: "connection_id"
  add_foreign_key "avo_mcp_server_access_tokens", "avo_mcp_server_connections", column: "connection_id"
  add_foreign_key "avo_mcp_server_events", "avo_mcp_server_connections", column: "connection_id"
  add_foreign_key "products", "suppliers"
  add_foreign_key "products", "users"
  add_foreign_key "products", "warehouses"
  add_foreign_key "purchase_orders", "products"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "purchase_orders", "warehouses"
  add_foreign_key "shipments", "warehouses"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "warehouses"
end
