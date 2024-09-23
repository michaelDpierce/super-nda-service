class AddProcessStatusToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :process_status, :string
  end
end
