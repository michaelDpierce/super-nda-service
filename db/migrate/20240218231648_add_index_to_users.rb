class AddIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :prefixmatch
    add_index :users, :fullname_match
    add_index :users, :email
  end
end