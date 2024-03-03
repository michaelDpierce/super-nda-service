class ContactModel < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :prefix
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :prefix_lookup
      t.string :fullname_lookup
      t.timestamps
    end
  end
end
