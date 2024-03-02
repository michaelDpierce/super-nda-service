class RemovePinned < ActiveRecord::Migration[7.1]
  def change
    remove_column :project_users, :pinned
    remove_column :project_users, :pinned_at
  end
end