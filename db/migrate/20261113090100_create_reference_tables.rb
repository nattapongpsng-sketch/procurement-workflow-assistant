class CreateReferenceTables < ActiveRecord::Migration[8.1]
  def change
    create_table :recommended_ais do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.text :capability
      t.string :vendor, null: false
      t.string :list_version, null: false
      t.date :approved_on
      t.boolean :highlighted, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :recommended_ais, [ :name, :list_version ], unique: true

    create_table :people do |t|
      t.string :title_prefix, null: false
      t.string :full_name, null: false
      t.string :position_short, null: false
      t.string :position_en
      t.string :employee_code
      t.string :unit_code, null: false
      t.timestamps
    end
    add_index :people, :employee_code, unique: true

    create_table :budget_sources do |t|
      t.string :ref_doc_no, null: false
      t.date :ref_doc_date, null: false
      t.string :owner_unit, null: false
      t.string :budget_type, null: false
      t.integer :fiscal_year, null: false
      t.string :account_name, null: false
      t.string :account_code, null: false
      t.string :cost_center, null: false
      t.decimal :limit_amount, precision: 15, scale: 2
      t.string :limit_basis
      t.date :spend_deadline
      t.text :description
      t.timestamps
    end
    add_index :budget_sources, :ref_doc_no, unique: true
  end
end
