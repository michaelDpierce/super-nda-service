class CreateProjectUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :project_users do |t|
      t.integer :project_id
      t.integer :user_id
      t.boolean :access, default: true
      t.boolean :admin, default: false
      t.boolean :pinned, default: true
      t.datetime :pinned_at, precision: nil
      t.datetime :last_viewed_at, precision: nil
      t.timestamps
    end
  end
end
