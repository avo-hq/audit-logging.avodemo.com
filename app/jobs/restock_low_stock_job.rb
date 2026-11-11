# Runs with no signed-in user, so audit logging names the job as what made each change.
class RestockLowStockJob < ApplicationJob
  def perform(units: 20)
    Product.low_stock.find_each { |product| product.restock!(units) }
  end
end
