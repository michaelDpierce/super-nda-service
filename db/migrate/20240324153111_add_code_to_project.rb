class AddCodeToProject < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :code, :string
    add_index :projects, :code

    Project.record_timestamps = false

    Project.find_each do |project|
      project.update_column(:code, rand(100000..999999).to_s)
    end
    
    Project.record_timestamps = true
  end
end
