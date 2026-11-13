class CreateCaseTables < ActiveRecord::Migration[8.1]
  def change
    create_table :procurement_cases do |t|
      t.references :workflow_template, null: false, foreign_key: true
      t.string :title, null: false
      t.string :status, null: false, default: "draft"
      t.json :data, null: false, default: {}
      t.string :created_by
      t.timestamps
    end
    add_index :procurement_cases, :status

    create_table :generated_documents do |t|
      t.references :procurement_case, null: false, foreign_key: true
      t.references :document_template, null: false, foreign_key: true
      t.integer :version, null: false
      t.string :status, null: false, default: "pending"
      t.json :data_snapshot, null: false, default: {}
      t.text :error_message
      t.datetime :generated_at
      t.timestamps
    end
    add_index :generated_documents, [ :procurement_case_id, :document_template_id, :version ],
              unique: true, name: "index_generated_documents_on_case_template_version"
  end
end
