class AddProjectToDocuments < ActiveRecord::Migration[7.1]
  def up
    # Step 1: Add the column without NOT NULL constraint
    add_column :documents, :project_id, :integer
    
    # Assuming you have a way to determine what the default project_id should be.
    # Step 2: Backfill existing documents with a default project_id.
    # This is a simplified example. You'll need to replace `default_project_id` 
    # with actual logic to determine the appropriate project_id for each document.
    default_project_id = Project.first.id
    Document.update_all(project_id: default_project_id)
    
    # Step 3: Change the column to be NOT NULL now that all rows have a project_id
    change_column_null :documents, :project_id, false

    # Optional: Add a foreign key constraint for referential integrity
    add_foreign_key :documents, :projects
  end

  def down
    # If you roll back this migration, remove the column (also removes the foreign key if added)
    remove_column :documents, :project_id
  end
end
