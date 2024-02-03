class AddContentToDirectoryFile < ActiveRecord::Migration[7.1]
  def change
    add_column :directory_files, :content, :text
  end
end
