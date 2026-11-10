# AVO_ADMIN_PASSWORD=secret bin/rails db:seed
# Sign in as avo@cado.com with that password, "secret" when it is unset. Re-running starts from scratch.

def progress_params(total:, title:)
  {
    total: total,
    format: "\e[32m%t : %B %p%% %c/%C [ %a ]\e[0m",
    progress_mark: "=",
    length: 90,
    starting_at: 0,
    title: " #{title}",
    title_width: 20,
    throttle_rate: 0.01,
    remainder_mark: "."
  }
end

RNG = Random.new(1477)
Faker::Config.random = RNG

require "active_support/testing/time_helpers"
extend ActiveSupport::Testing::TimeHelpers

# The base data is not part of the audit log: no activities and no versions. db/seeds/activity.rb makes those.
# Made before the log's 60 days begin, so no record is newer than its first change.
travel_to(61.days.ago) do
  Avo::AuditLogging.disabled do
    PaperTrail.request(enabled: false) do
      # ------------------------------- START CLEAN -------------------------------- #
      connection = ActiveRecord::Base.connection
      kept = %w[schema_migrations ar_internal_metadata ruby_llm_models]
      connection.disable_referential_integrity do
        (connection.tables - kept).each { |table| connection.execute("DELETE FROM #{connection.quote_table_name(table)}") }
      end

      # ---------------------------------- USERS ---------------------------------- #
      # The people who work in the panel, and so author its audit log. Invented names, example.com addresses.
      staff = [
        {first_name: "Avo", last_name: "Cado", email: "avo@cado.com"},
        {first_name: "Maya", last_name: "Lindqvist", email: "maya@example.com"},
        {first_name: "Tomas", last_name: "Okafor", email: "tomas@example.com"},
        {first_name: "Priya", last_name: "Raman", email: "priya@example.com"},
        {first_name: "Jonas", last_name: "Weber", email: "jonas@example.com"}
      ]
      customers_number = 24

      users_progress_bar = ProgressBar.create(progress_params(total: staff.size + customers_number, title: "Creating users"))

      staff.each do |attributes|
        User.create!(**attributes, password: ENV.fetch("AVO_ADMIN_PASSWORD", "secret"),
          roles: {admin: true, manager: false, writer: false})
        users_progress_bar.increment
      end

      customers = Array.new(customers_number) do
        FactoryBot.create(:user, email: Faker::Internet.unique.email(domain: "example.com")).tap { users_progress_bar.increment }
      end

      # -------------------------------- WAREHOUSES ---------------------------------- #
      warehouses = ["North Warehouse", "South Warehouse", "East Depot", "West Depot", "Central Hub"].map do |name|
        Warehouse.create!(name: name, inventory_value_cents: 0)
      end

      # ---------------------------------- PRODUCTS ---------------------------------- #
      curated_products = [
        {name: "iPhone 15", price_usd: 799.00, manufacturer: "Apple", category: "Phones"},
        {name: "iPhone 15 Pro Max", price_usd: 1199.00, manufacturer: "Apple", category: "Phones"},
        {name: "MacBook Air 13-inch (M3)", price_usd: 1099.00, manufacturer: "Apple", category: "Computers"},
        {name: "MacBook Pro 14-inch (M3 Pro)", price_usd: 1999.00, manufacturer: "Apple", category: "Computers"},
        {name: "iPad Air (M2)", price_usd: 599.00, manufacturer: "Apple", category: "Computers"},
        {name: "iPad Pro 11-inch (M4)", price_usd: 999.00, manufacturer: "Apple", category: "Computers"},
        {name: "Apple Watch Series 10", price_usd: 399.00, manufacturer: "Apple", category: "Wearables"},
        {name: "Apple Watch Ultra 2", price_usd: 799.00, manufacturer: "Apple", category: "Wearables"},
        {name: "AirPods Pro (2nd generation)", price_usd: 249.00, manufacturer: "Apple", category: "Music players"},
        {name: "AirPods Max", price_usd: 549.00, manufacturer: "Apple", category: "Music players"},
        {name: "Apple TV 4K (128GB)", price_usd: 149.00, manufacturer: "Apple", category: "Computers"},
        {name: "Samsung Galaxy S24", price_usd: 799.99, manufacturer: "Samsung", category: "Phones"},
        {name: "Samsung Galaxy S24 Ultra", price_usd: 1299.99, manufacturer: "Samsung", category: "Phones"},
        {name: "Galaxy Watch6", price_usd: 299.99, manufacturer: "Samsung", category: "Wearables"},
        {name: "Galaxy Buds2 Pro", price_usd: 229.99, manufacturer: "Samsung", category: "Music players"},
        {name: "Google Pixel 9", price_usd: 799.00, manufacturer: "Google", category: "Phones"},
        {name: "Pixel Watch 3", price_usd: 349.99, manufacturer: "Google", category: "Wearables"},
        {name: "Sony WH-1000XM5", price_usd: 399.99, manufacturer: "Sony", category: "Music players"},
        {name: "Bose QuietComfort Ultra Headphones", price_usd: 429.00, manufacturer: "Bose", category: "Music players"},
        {name: "Surface Laptop 7", price_usd: 1299.00, manufacturer: "Microsoft", category: "Computers"},
        {name: "Dell XPS 13", price_usd: 1099.00, manufacturer: "Dell", category: "Computers"},
        {name: "HP Spectre x360 14", price_usd: 1299.99, manufacturer: "HP", category: "Computers"},
        {name: "Lenovo ThinkPad X1 Carbon", price_usd: 1499.00, manufacturer: "Lenovo", category: "Computers"}
      ].shuffle(random: RNG)

      products_progress_bar = ProgressBar.create(progress_params(total: curated_products.size, title: "Creating products"))

      curated_products.each do |data|
        Product.create!(
          name: data[:name],
          description: "#{data[:manufacturer]} #{data[:name]} in the #{data[:category]} category.",
          price_cents: (data[:price_usd].to_f * 100).round,
          category: data[:category],
          quantity: RNG.rand(4..50),
          is_featured: RNG.rand < 0.25,
          manufacturer: data[:manufacturer],
          user: customers.sample(random: RNG),
          warehouse: warehouses.sample(random: RNG)
        )
        products_progress_bar.increment
      end

      warehouses.each(&:recalc_total!)
    end
  end
end

# Every entry of the audit log, made through the app's real paths. SKIP_ACTIVITY=1 leaves the log empty.
load Rails.root.join("db/seeds/activity.rb") unless ENV["SKIP_ACTIVITY"]
