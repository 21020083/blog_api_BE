class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :entity_type, null: false
      t.bigint :entity_id, null: false
      t.timestamps
    end

    add_index :audit_logs, [ :entity_type, :entity_id ]
  end
end
