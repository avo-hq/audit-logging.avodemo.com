class CreateStockMovements < ActiveRecord::Migration[7.2]
  def change
    create_table :stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :warehouse, foreign_key: true
      t.integer :kind, null: false
      t.integer :quantity, null: false
      t.string :note
      t.timestamps
    end
  end
end
