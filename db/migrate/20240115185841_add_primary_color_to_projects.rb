class AddPrimaryColorToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :primary_color, :string, default: '#1F1708'
  end
end
