class Avo::Cards::WarehouseValue < Avo::Cards::ChartkickCard
  self.id = "warehouse_value"
  self.label = "Inventory value by warehouse"
  self.description = "What sits on each one's shelves, at its price"
  self.chart_type = :bar_chart
  self.rows = 2
  self.flush = false
  self.scale = true
  self.chart_options = {prefix: "$", thousands: ","}

  def query
    values = Warehouse.order(inventory_value_cents: :desc).pluck(:name, :inventory_value_cents)
    result [{name: "Value", data: values.map { |name, cents| [name, cents / 100] }}]
  end
end
