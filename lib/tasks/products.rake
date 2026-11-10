namespace :products do
  desc "Mark down overstocked products by 10%"
  task clearance: :environment do
    Product.where("quantity > ?", 40).find_each do |product|
      product.update!(price_cents: (product.price_cents * 0.9).round(-2))
    end
  end
end
