class CleanUpDb < ActiveRecord::Migration[7.1]
  def change
    remove_column :directory_files, :blob_id
    remove_column :project_users, :role
    remove_column :users, :prefix
    remove_column :users, :title
    remove_column :users, :company
    remove_column :users, :company_role_type
    remove_column :users, :role
    remove_column :users, :prefixmatch
    remove_column :users, :fullname_match
  end
end
