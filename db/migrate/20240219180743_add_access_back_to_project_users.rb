class AddAccessBackToProjectUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :project_users, :access, :boolean, default: false
    change_column :project_users, :role, :integer, default: 1
  end
end
