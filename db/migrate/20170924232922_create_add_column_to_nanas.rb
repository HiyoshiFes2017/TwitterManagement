class CreateAddColumnToNanas < ActiveRecord::Migration[5.1]
  def change
    add_column :nanas, :status, :integer, :null => false, :default => 0
  end
end
