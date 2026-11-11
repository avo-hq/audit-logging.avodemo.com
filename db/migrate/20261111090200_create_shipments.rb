class CreateShipments < ActiveRecord::Migration[7.2]
  def change
    create_table :shipments do |t|
      t.string :reference, null: false
      t.references :warehouse, null: false, foreign_key: true
      t.string :carrier, null: false
      t.string :tracking_number
      t.string :destination, null: false
      t.integer :status, default: 0, null: false
      t.datetime :shipped_at
      t.timestamps
    end
  end
end
