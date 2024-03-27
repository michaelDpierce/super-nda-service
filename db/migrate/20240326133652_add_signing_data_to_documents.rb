class AddSigningDataToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :counter_party_full_name, :string
    add_column :documents, :counter_party_email, :string
    add_column :documents, :counter_party_date, :datetime
    add_column :documents, :counter_party_ip, :string
    add_column :documents, :counter_party_user_agent, :string
  end
end
