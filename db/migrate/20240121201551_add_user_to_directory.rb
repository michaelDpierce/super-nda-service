class AddUserToDirectory < ActiveRecord::Migration[7.1]
  def change
    add_column :directories, :user_id, :integer
  end
end
