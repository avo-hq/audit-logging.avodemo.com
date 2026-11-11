class Avo::Dashboards::Overview < Avo::Dashboards::BaseDashboard
  self.id = "overview"
  self.name = "Overview"
  self.description = "Where the warehouses stand today"
  self.grid_cols = 3

  def cards
    card Avo::Cards::InventoryValue
    card Avo::Cards::LowStock
    card Avo::Cards::OverdueOrders
    card Avo::Cards::ChangesLogged
    card Avo::Cards::ChangesFromOutside
    card Avo::Cards::StockReceived
    card Avo::Cards::WarehouseValue
  end
end
