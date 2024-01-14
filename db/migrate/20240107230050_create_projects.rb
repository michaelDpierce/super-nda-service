class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.integer :user_id
      t.integer :status, default: 0
      t.timestamps
    end
  end
end
