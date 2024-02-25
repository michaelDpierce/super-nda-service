class RemoveDisplayDateFromDirectory < ActiveRecord::Migration[7.1]
  def change
    remove_column :directories, :display_date, :datetime
  end
end
