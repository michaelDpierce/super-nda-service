class CreateProjectContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :project_contacts do |t|
      t.integer :project_id
      t.integer :contact_id
      t.string :role
      t.timestamps
    end

    add_index :project_contacts, :project_id
    add_index :project_contacts, [:project_id, :contact_id], unique: true
  end
end
