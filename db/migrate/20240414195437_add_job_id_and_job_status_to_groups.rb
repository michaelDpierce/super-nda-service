class AddJobIdAndJobStatusToGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :job_id, :string
    add_column :groups, :job_status, :integer, default: 0
  end
end
