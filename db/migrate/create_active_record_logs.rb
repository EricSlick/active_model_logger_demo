class CreateActiveModelLogs < ActiveRecord::Migration[7.1]
  def change
    # Detect database type for compatibility
    adapter_name = ActiveRecord::Base.connection.adapter_name.downcase

    case adapter_name
    when 'postgresql'
      create_table :active_model_logs, id: :uuid do |t|
        t.references :loggable, null: false, polymorphic: true, index: true
        t.text :message, default: ""
        t.jsonb :metadata
        t.timestamps
      end
    when 'mysql2', 'mysql'
      create_table :active_model_logs do |t|
        t.references :loggable, null: false, polymorphic: true, index: true
        t.text :message, default: ""
        t.json :metadata
        t.timestamps
      end
    else
      # SQLite and other databases
      create_table :active_model_logs do |t|
        t.string :loggable_type, null: false
        t.integer :loggable_id, null: false
        t.text :message, default: ""
        t.text :metadata
        t.timestamps
      end

      add_index :active_model_logs, [ :loggable_type, :loggable_id ]
    end
  end
end
