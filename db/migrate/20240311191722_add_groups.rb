class AddGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :status, default: 0 #queued
      t.integer :user_id
      t.integer :project_id
      t.text :notes
      t.timestamps
    end

    add_index :groups, [:project_id, :name, :status], unique: false
  end
end
