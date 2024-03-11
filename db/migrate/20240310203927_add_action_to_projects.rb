class AddActionToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :action, :integer, default: 0
  end
end
