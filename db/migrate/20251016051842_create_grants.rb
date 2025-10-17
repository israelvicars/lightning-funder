class CreateGrants < ActiveRecord::Migration[8.0]
  def change
    create_table :grants do |t|
      # Mandatory fields (A-E)
      t.string :funder_name, null: false
      t.string :grant_name, null: false
      t.string :status, null: false
      t.string :project_name, null: false
      t.integer :fiscal_year, null: false

      # Optional date fields (F-M)
      t.date :deadline
      t.date :submission_date
      t.date :date_awarded_declined
      t.date :award_start_date
      t.date :award_end_date
      t.date :date_notified

      # Optional amount fields (K-L)
      t.decimal :amount_requested, precision: 10, scale: 2
      t.decimal :amount_awarded, precision: 10, scale: 2

      # Optional text fields (N-W)
      t.text :upcoming_tasks
      t.string :portal_website
      t.string :portal_username
      t.string :portal_password
      t.string :funder_location
      t.text :funder_contact_info
      t.string :funder_type
      t.text :opportunity_notes
      t.text :funder_notes
      t.string :grant_owner

      # Import tracking
      t.references :import_batch, foreign_key: true
      t.integer :row_number

      t.timestamps
    end

    add_index :grants, :funder_name
    add_index :grants, :status
    add_index :grants, :fiscal_year
  end
end
