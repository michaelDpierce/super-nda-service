class AddAttributesToProjectUser < ActiveRecord::Migration[7.1]
  def change
    add_column :project_users, :domain, :string
    add_column :project_users, :group_id, :integer
  end
end