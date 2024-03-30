class AdjustBigIntColumns < ActiveRecord::Migration[7.1]
  def change
    change_column :documents, :owner, :bigint
    change_column :documents, :project_id, :bigint

    change_column :groups, :user_id, :bigint
    change_column :groups, :project_id, :bigint
    change_column :groups, :last_document_id, :bigint

    change_column :project_users, :project_id, :bigint
    change_column :project_users, :user_id, :bigint
    change_column :project_users, :group_id, :bigint

    change_column :projects, :user_id, :bigint
    change_column :projects, :authorized_agent_of_signatory_user_id, :bigint
  end
end
