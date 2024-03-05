class CreateMeetingAttendances < ActiveRecord::Migration[7.1]
  def change
    create_table :meeting_attendances do |t|
      t.integer :status
      t.references :contact, null: false, foreign_key: true
      t.references :directory_file, null: false, foreign_key: true

      t.timestamps
    end
  end
end
