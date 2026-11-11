class Avo::Cards::LowStock < Avo::Cards::MetricCard
  self.id = "low_stock"
  self.label = "Low on stock"
  self.description = "Products with #{Product::LOW_STOCK} or fewer left"

  def query
    result Product.low_stock.count
  end
end
