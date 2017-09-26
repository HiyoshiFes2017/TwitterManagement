class CreateaddImagesToNanas < ActiveRecord::Migration[5.1]
  def change
    remove_column :nanas, :file
    add_column :nanas, :files, :json
  end
end
