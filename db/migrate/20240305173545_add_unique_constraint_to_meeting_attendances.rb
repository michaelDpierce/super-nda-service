class AddUniqueConstraintToMeetingAttendances < ActiveRecord::Migration[7.1]
  def change
    add_index :meeting_attendances, [:contact_id, :directory_file_id], unique: true, name: 'index_meeting_attendances_on_contact_id_and_directory_file_id'
  end
end
