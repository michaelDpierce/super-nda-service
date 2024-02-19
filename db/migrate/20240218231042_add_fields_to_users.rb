class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :prefix, :string
    add_column :users, :title, :string
    add_column :users, :company, :string
    add_column :users, :company_role_type, :string
    add_column :users, :role, :string
    add_column :users, :prefixmatch, :string
    add_column :users, :fullname_match, :string
  end
end
