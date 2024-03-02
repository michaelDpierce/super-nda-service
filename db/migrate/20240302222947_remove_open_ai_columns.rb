class RemoveOpenAiColumns < ActiveRecord::Migration[7.1]
  def change
    remove_column :directory_files, :openai_attendance
    remove_column :directory_files, :openai_display_date
    remove_column :directory_files, :openai_location
  end
end
