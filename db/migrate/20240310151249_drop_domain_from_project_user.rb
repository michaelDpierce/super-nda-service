class DropDomainFromProjectUser < ActiveRecord::Migration[7.1]
  def change
    remove_column :project_users, :domain, :string
  end
end
