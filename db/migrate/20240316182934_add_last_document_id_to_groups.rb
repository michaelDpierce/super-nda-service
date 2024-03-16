class AddLastDocumentIdToGroups < ActiveRecord::Migration[7.1]
  def change
    # Add the last_document_id column to the groups table
    add_column :groups, :last_document_id, :integer
    add_index :groups, :last_document_id

    # Temporarily disable timestamp updates to avoid updated_at changes
    Group.record_timestamps = false

    # Iterate over each Group to find and set the last_document_id
    Group.find_each do |group|
      last_document = group.documents.order(created_at: :desc).first
      # Update the group's last_document_id without modifying the updated_at column
      group.update_column(:last_document_id, last_document.id) if last_document
    end

    # Re-enable timestamp updates
    Group.record_timestamps = true
  end
end
