class Avo::Dashboards::Overview < Avo::Dashboards::BaseDashboard
  self.id = "overview"
  self.name = "Overview"
  self.description = "Where the warehouses stand today"
  self.grid_cols = 3

  def cards
    card Avo::Cards::InventoryValue
    card Avo::Cards::LowStock
    card Avo::Cards::OverdueOrders
  end
end
