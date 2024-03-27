class AddPartySigningToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :party_full_name, :string
    add_column :documents, :party_email, :string
    add_column :documents, :party_date, :datetime
    add_column :documents, :party_ip, :string
    add_column :documents, :party_user_agent, :string
  end
end
