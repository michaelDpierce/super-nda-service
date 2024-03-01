class AddDefaultCommittee < ActiveRecord::Migration[7.1]
  def up
    change_column_default :directory_files, :committee, from: nil, to: 'None'
  end

  def down
    change_column_default :directory_files, :committee, from: 'None', to: nil
  end
end
