# A host's own origin: every change inside the block is logged as the supplier feed's, linked to the warehouse.
class SupplierFeedJob < ApplicationJob
  def perform(warehouse, markup_percent)
    Avo::AuditLogging::Origin.with("supplier_feed", record: warehouse) do
      warehouse.products.find_each do |product|
        product.update!(price_cents: (product.price_cents * (100 + markup_percent) / 100.0).round(-2))
      end
    end
  end
end
