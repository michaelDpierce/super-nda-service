class AdjustProjectTable < ActiveRecord::Migration[7.1]
  def change
    remove_column :projects, :action
    change_column :projects, :start_date, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
  end
end