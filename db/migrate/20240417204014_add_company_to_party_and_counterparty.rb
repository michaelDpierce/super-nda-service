class AddCompanyToPartyAndCounterparty < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :party_company, :string
    add_column :documents, :counter_party_company, :string
  end
end
