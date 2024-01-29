class CreateDirectoryFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :directory_files do |t|
      t.integer :directory_id, index: true
      t.integer :blob_id, index: true
      t.integer :user_id
      t.integer :project_id
      t.string :filename
    end
  end
end
