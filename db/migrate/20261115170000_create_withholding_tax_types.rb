# Withholding tax rates by income type (Requirement FR-19). Data, not code: finance
# staff confirm and maintain the rates (OPEN_QUESTIONS Q36).
class CreateWithholdingTaxTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :withholding_tax_types do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.decimal :rate, precision: 5, scale: 4, null: false
      t.decimal :minimum_amount, precision: 15, scale: 2, null: false, default: 0
      t.string :legal_reference
      t.text :note
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :withholding_tax_types, :code, unique: true
  end
end
