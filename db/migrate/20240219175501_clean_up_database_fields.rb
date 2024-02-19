class CleanUpDatabaseFields < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :app_admin
    remove_column :projects, :primary_color
    remove_column :project_users, :access
    add_column :project_users, :role, :integer, default: 0
  end
end