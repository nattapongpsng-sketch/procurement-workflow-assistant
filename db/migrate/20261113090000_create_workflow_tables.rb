class CreateWorkflowTables < ActiveRecord::Migration[8.1]
  def change
    create_table :workflow_templates do |t|
      t.string :code, null: false
      t.integer :version, null: false
      t.string :name, null: false
      t.text :description
      t.jsonb :keywords, null: false, default: []
      t.string :category
      t.string :procurement_method
      t.jsonb :legal_basis, null: false, default: []
      t.jsonb :eligibility_rules, null: false, default: []
      t.jsonb :field_groups, null: false, default: []
      t.jsonb :summary, null: false, default: {}
      t.string :status, null: false, default: "draft"
      t.string :source_digest
      t.datetime :published_at
      t.timestamps
    end
    add_index :workflow_templates, [ :code, :version ], unique: true
    add_index :workflow_templates, :status

    create_table :workflow_steps do |t|
      t.references :workflow_template, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :title, null: false
      t.text :description
      t.string :actor_role
      t.jsonb :output_documents, null: false, default: []
      t.jsonb :required_attachments, null: false, default: []
      t.text :tips
      t.string :estimated_duration
      t.boolean :confirmed, null: false, default: true
      t.timestamps
    end
    add_index :workflow_steps, [ :workflow_template_id, :position ], unique: true

    create_table :field_definitions do |t|
      t.references :workflow_template, null: false, foreign_key: true
      t.string :key, null: false
      t.string :label, null: false
      t.string :group_key, null: false
      t.integer :position, null: false
      t.string :field_type, null: false
      t.boolean :required, null: false, default: false
      t.text :help
      t.text :example
      t.text :why
      t.jsonb :validation, null: false, default: {}
      t.jsonb :computed
      t.jsonb :options, null: false, default: {}
      t.timestamps
    end
    add_index :field_definitions, [ :workflow_template_id, :key ], unique: true

    create_table :document_templates do |t|
      t.string :code, null: false
      t.integer :version, null: false
      t.string :name, null: false
      t.text :description
      t.string :template_path, null: false
      t.jsonb :field_keys, null: false, default: []
      t.string :checksum
      t.timestamps
    end
    add_index :document_templates, [ :code, :version ], unique: true

    create_table :workflow_documents do |t|
      t.references :workflow_template, null: false, foreign_key: true
      t.references :document_template, null: false, foreign_key: true
      t.integer :step_position
      t.timestamps
    end
    add_index :workflow_documents, [ :workflow_template_id, :document_template_id ], unique: true
  end
end
