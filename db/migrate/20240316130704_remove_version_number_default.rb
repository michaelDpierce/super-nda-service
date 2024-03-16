class RemoveVersionNumberDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default :documents, :version_number, :nil
  end
end
