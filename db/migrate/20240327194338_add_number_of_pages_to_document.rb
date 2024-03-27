class AddNumberOfPagesToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :number_of_pages, :integer
  end
end
