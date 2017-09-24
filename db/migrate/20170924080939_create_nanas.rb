class CreateNanas < ActiveRecord::Migration[5.1]
  def change
    create_table(:nanas) do |t|
      t.string :comment
      t.string :file
    end
  end
end
