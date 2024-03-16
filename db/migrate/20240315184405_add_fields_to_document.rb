class AddFieldsToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :owner, :integer, default: 0
    add_column :documents, :version_number, :integer, default: 1
    remove_column :documents, :state
  end
end