class Avo::Cards::InventoryValue < Avo::Cards::MetricCard
  self.id = "inventory_value"
  self.label = "Inventory value"
  self.description = "Every product in stock, at its price"
  self.prefix = "$"

  def query
    result Warehouse.sum(:inventory_value_cents) / 100
  end
end
