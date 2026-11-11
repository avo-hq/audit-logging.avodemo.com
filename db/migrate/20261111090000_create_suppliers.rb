class CreateSuppliers < ActiveRecord::Migration[7.2]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_email
      t.string :country
      t.integer :lead_time_days, default: 7, null: false
      t.timestamps
    end

    add_reference :products, :supplier, foreign_key: true
    add_column :products, :sku, :string
  end
end
