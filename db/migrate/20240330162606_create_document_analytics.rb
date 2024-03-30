class CreateDocumentAnalytics < ActiveRecord::Migration[7.1]
  def change
    create_table :document_analytics do |t|
      t.bigint :project_id, null: false
      t.bigint :group_id, null: false
      t.bigint :document_id, null: false
      t.integer :version_number
      t.integer :action_type
      t.timestamps
    end
  end
end