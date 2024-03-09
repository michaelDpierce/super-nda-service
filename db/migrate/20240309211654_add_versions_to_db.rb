class AddVersionsToDb < ActiveRecord::Migration[7.1]
  def change
    create_table :versions do |t|
      t.string   :item_type, null: false
      t.bigint   :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.text     :object, limit: 1_073_741_823

      # Known issue in MySQL: fractional second precision
      # -------------------------------------------------
      #
      # MySQL timestamp columns do not support fractional seconds unless
      # defined with "fractional seconds precision". MySQL users should manually
      # add fractional seconds precision to this migration, specifically, to
      # the `created_at` column.
      # (https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html)
      #
      # MySQL users should also upgrade to at least rails 4.2, which is the first
      # version of ActiveRecord with support for fractional seconds in MySQL.
      # (https://github.com/rails/rails/pull/14359)
      #
      # MySQL users should use the following line for `created_at`
      # t.datetime :created_at, limit: 6
      t.datetime :created_at
    end
    
    add_index :versions, %i[item_type item_id]
    add_column :versions, :ip_address, :string
    add_column :versions, :user_agent, :string
  end
end
