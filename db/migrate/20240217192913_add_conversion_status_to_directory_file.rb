class AddConversionStatusToDirectoryFile < ActiveRecord::Migration[7.1]
  def change
    add_column :directory_files, :conversion_status, :integer, default: 0
  end
end
