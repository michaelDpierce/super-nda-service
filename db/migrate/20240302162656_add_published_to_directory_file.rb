class AddPublishedToDirectoryFile < ActiveRecord::Migration[7.1]
  def change
    add_column :directory_files, :published, :boolean, default: false
  end
end
