class AddStartAndEndDateToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :start_date, :datetime
    add_column :projects, :end_date, :datetime
  end
end
