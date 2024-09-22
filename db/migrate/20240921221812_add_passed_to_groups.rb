class AddPassedToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :passed, :boolean, default: :false
  end
end
