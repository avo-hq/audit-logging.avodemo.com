class CreatePurchaseOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :purchase_orders do |t|
      t.string :number, null: false
      t.references :supplier, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :status, default: 0, null: false
      t.date :expected_on
      t.timestamps
    end
  end
end
