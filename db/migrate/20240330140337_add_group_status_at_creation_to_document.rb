class AddGroupStatusAtCreationToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :group_status_at_creation, :integer
  end
end
