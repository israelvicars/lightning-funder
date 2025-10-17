class CreateImportBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :import_batches do |t|
      t.string :filename
      t.string :status, default: 'pending'
      t.integer :total_rows
      t.integer :successful_rows, default: 0
      t.integer :failed_rows, default: 0
      t.jsonb :error_details

      t.timestamps
    end

    add_index :import_batches, :status
  end
end
