class AddIpAddressToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :ip_address, :string
    add_column :versions, :user_agent, :string
  end
end
