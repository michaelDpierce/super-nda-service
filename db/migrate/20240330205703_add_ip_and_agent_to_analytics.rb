class AddIpAndAgentToAnalytics < ActiveRecord::Migration[7.1]
  def change
    add_column :document_analytics, :counter_party_ip, :string
    add_column :document_analytics, :counter_party_user_agent, :string
  end
end
