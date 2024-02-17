class AddCommitteeToDirectoryFile < ActiveRecord::Migration[7.1]
  def change
    add_column :directory_files, :committee, :string
  end
end
