class ChangeFullnametoFullName < ActiveRecord::Migration[7.1]
  def change
    rename_column :contacts, :fullname_lookup, :full_name_lookup
  end
end
