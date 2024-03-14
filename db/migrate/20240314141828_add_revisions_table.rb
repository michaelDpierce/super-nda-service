class AddRevisionsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :revisions do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :revision_number
      t.integer :sub_revision_number
      t.string :side

      t.timestamps
    end
  end
end
