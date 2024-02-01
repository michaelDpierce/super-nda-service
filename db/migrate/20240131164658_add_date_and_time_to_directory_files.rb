class AddDateAndTimeToDirectoryFiles < ActiveRecord::Migration[7.1]
  def change
    add_column :directory_files, :created_at, :datetime, precision: nil
    add_column :directory_files, :updated_at, :datetime, precision: nil
    add_column :directory_files, :display_date, :datetime, precision: nil
  end
end
