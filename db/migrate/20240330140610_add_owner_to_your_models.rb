class AddOwnerToYourModels < ActiveRecord::Migration[7.1]
  def change
    add_reference :documents, :creator, foreign_key: { to_table: :users }, type: :bigint
  end
end
