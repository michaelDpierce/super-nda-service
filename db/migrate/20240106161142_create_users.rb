class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email
      t.datetime :timezone, default: "Eastern Time (US & Canada)"
      t.string "first_name"
      t.string "last_name"
      t.boolean "app_admin", default: false
      t.string "stripe_customer_id"
      t.string "source_id"
      t.timestamps
    end
  end
end
