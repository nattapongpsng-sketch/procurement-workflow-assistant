# Requirement FR-28: audit log of every create / update / approve / cancel that cannot be
# edited or deleted. Enforced in PostgreSQL with triggers (kept in schema.rb by the fx gem).
class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.datetime :occurred_at, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.string :summary
      t.jsonb :changes_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
    end
    add_index :audit_events, [ :auditable_type, :auditable_id ]
    add_index :audit_events, :occurred_at
    add_index :audit_events, :action

    create_function :prevent_audit_event_changes
    create_trigger :audit_events_append_only, on: :audit_events
    create_trigger :audit_events_no_truncate, on: :audit_events
  end
end
