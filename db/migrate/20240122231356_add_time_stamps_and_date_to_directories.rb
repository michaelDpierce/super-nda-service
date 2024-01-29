class AddTimeStampsAndDateToDirectories < ActiveRecord::Migration[7.1]
  def change
    add_column :directories, :created_at, :datetime, precision: nil
    add_column :directories, :updated_at, :datetime, precision: nil
    add_column :directories, :display_date, :datetime, precision: nil
  end
end
