class AddPositionToSuppliers < ActiveRecord::Migration[7.2]
  def change
    add_column :suppliers, :position, :integer
  end
end
