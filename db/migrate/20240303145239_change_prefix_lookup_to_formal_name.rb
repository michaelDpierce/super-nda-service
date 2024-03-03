class ChangePrefixLookupToFormalName < ActiveRecord::Migration[7.1]
  def change
    rename_column :contacts, :prefix_lookup, :formal_name_lookup
  end
end

