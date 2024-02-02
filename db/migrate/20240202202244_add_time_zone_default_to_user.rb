class AddTimeZoneDefaultToUser < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :timezone, :string, default:'Eastern Time (US & Canada)'
  end
end
