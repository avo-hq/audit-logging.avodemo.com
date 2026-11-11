class Avo::Cards::OverdueOrders < Avo::Cards::MetricCard
  self.id = "overdue_orders"
  self.label = "Overdue orders"
  self.description = "Sent, and past the date the supplier promised"

  def query
    result PurchaseOrder.sent.where(expected_on: ...Date.current).count
  end
end
