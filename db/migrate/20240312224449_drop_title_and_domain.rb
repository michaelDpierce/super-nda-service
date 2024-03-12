class DropTitleAndDomain < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :domain
    remove_column :users, :title
  end
end