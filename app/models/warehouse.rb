class Warehouse < ApplicationRecord
  has_paper_trail

  has_many :products, after_add: :recalc_total!, after_remove: :recalc_total!
  has_many :purchase_orders
  has_many :shipments
  has_many :stock_movements

  monetize :inventory_value_cents

  def recalc_total!(product = nil)
    update!(inventory_value_cents: products.sum("price_cents * quantity"))
  end
end


