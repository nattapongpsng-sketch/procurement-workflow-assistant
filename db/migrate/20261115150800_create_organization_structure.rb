# Requirement FR-01 (หน่วยงาน ส่วนงาน ตำแหน่ง ผู้ใช้) and NFR-05 (role-based access by department).
class CreateOrganizationStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :short_name
      t.string :code, null: false
      t.timestamps
    end
    add_index :organizations, :code, unique: true

    create_table :departments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :departments }
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :departments, [ :organization_id, :code ], unique: true

    create_table :positions do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :title, null: false
      t.string :short_title
      t.timestamps
    end
    add_index :positions, [ :organization_id, :title ], unique: true

    change_table :users, bulk: true do |t|
      t.string :name, null: false, default: ""
      t.references :department, foreign_key: true
      t.references :position, foreign_key: true
      t.references :person, foreign_key: true
      t.string :roles, array: true, null: false, default: []
      t.boolean :active, null: false, default: true
    end
    add_index :users, :roles, using: :gin

    change_table :procurement_cases, bulk: true do |t|
      t.references :department, foreign_key: true
      t.references :created_by_user, foreign_key: { to_table: :users }
    end
  end
end
