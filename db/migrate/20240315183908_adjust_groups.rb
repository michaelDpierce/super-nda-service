class AdjustGroups < ActiveRecord::Migration[7.1]
  def change
    change_column :groups, :status, :integer, default: 1
  end
end


