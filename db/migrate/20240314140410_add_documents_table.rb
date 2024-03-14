class AddDocumentsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.references :group, null: false, foreign_key: true
      t.string :state
      t.timestamps
    end
  end
end
