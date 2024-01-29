class CreateDirectories < ActiveRecord::Migration[7.1]
  def change
    create_table :directories do |t|
      t.string :name
      t.integer :project_id
      t.string :slug, index: true
      t.string :ancestry, index: true
      t.integer :ancestry_depth, default: 0
    end

    add_index(:directories, %i[slug project_id ancestry], unique: true)
    add_index(:directories, :project_id)
  end
end
