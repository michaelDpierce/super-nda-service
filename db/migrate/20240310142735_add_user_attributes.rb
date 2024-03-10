class AddUserAttributes < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :domain, :string
  end
end
