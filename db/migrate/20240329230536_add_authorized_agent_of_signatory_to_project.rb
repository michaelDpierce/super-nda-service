class AddAuthorizedAgentOfSignatoryToProject < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :authorized_agent_of_signatory_user_id, :integer
  end
end
