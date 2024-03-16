class AddPartyAndCounterpartyCountToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :party_count, :integer, default: 0
    add_column :projects, :counter_party_count, :integer, default: 0
  end
end
