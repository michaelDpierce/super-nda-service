class AddCodeToGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :code, :string
    add_index :groups, :code

    Group.record_timestamps = false

    Group.find_each do |group|
      group.update_column(:code, rand(100000..999999).to_s)
    end
    
    Group.record_timestamps = true
  end
end
