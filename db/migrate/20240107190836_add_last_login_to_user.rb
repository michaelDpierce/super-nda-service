class AddLastLoginToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :last_login, :datetime
    remove_column :users, :stripe_customer_id
  end
end
