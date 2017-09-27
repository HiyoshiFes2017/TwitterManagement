class CreateAddMediaIdsToNanas < ActiveRecord::Migration[5.1]
  def change
    add_column :nanas, :media_ids, :string
  end
end
