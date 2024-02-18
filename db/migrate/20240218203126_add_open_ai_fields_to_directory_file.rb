class AddOpenAiFieldsToDirectoryFile < ActiveRecord::Migration[7.1]
  def change
    add_column :directory_files, :openai_attendance, :text
    add_column :directory_files, :openai_display_date, :datetime
    add_column :directory_files, :openai_location, :text
  end
end
