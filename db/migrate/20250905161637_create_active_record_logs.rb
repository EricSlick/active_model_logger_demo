class CreateActiveRecordLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :active_record_logs do |t|
      t.string :loggable_type, null: false
      t.integer :loggable_id, null: false
      t.text :message, default: ""
      t.text :metadata
      t.timestamps
    end

    add_index :active_record_logs, [ :loggable_type, :loggable_id ]
  end
end
