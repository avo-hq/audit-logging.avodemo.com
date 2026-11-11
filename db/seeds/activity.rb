# Fills the audit log the way a busy team would: every entry is recorded by the gems themselves, from real
# requests to the panel, the MCP server, the REST API and the AI chat, and from a job, a rake task, the console
# and a sign-up page. Only the timestamps are moved afterwards, to spread the entries over the last 60 days.
require "warden/test/helpers"
require_relative "fake_llm"

module ActivitySeed
  extend Warden::Test::Helpers
  extend ActiveSupport::Testing::TimeHelpers
  extend self

  RESULTS = Hash.new(0)
  PROBLEMS = []

  def run
    Warden.test_mode!
    ActionController::Base.allow_forgery_protection = false
    # The chat's response job and its titler run as part of the request that starts them.
    ActiveJob::Base.queue_adapter = :inline
    # Development checks for pending migrations on each request, and a migration dated after the travelled clock fails it.
    ActiveRecord.validate_migration_timestamps = false

    # Each phase runs at its own moment of the last 60 days, with the clock travelled there, so every timestamp
    # agrees: the entry, its version and the diff's updated_at, the connection log, the chat. Interleaved, so every
    # stretch has a mix of the panel and everything else.
    phases = [
      *panel(0..5), -> { mcp_work(0) }, *panel(6..9), -> { api_work(0) }, *panel(10..13), -> { mcp_work(1) },
      -> { ai_work(0) }, *panel(14..17), -> { api_work(1) }, -> { jobs_work }, *panel(18..22), -> { mcp_work(2) },
      -> { ai_work(1) }, *panel(23..29), -> { undo_work }
    ]
    phases.zip(timeline(phases.size)).each do |phase, at|
      travel_to(@clock = at)
      phase.call
    end
    travel_back
    @clock = nil

    # These start processes or pages of their own, so they happen now, after the travelled phases.
    scripts_work
    sign_up_work

    report
  ensure
    travel_back
    ActiveJob::Base.queue_adapter = Rails.application.config.active_job.queue_adapter || :async
  end

  def panel(rounds) = rounds.map { |round| -> { panel_work(round..round) } }

  # Weekday working hours mostly, oldest first, ending a couple of hours ago.
  def timeline(count)
    Array.new(count) do
      day = RNG.rand(1..59).days.ago.to_date
      day -= 2 if day.saturday? && RNG.rand < 0.8
      day -= 2 if day.sunday? && RNG.rand < 0.8
      day.in_time_zone.change(hour: 8 + RNG.rand(9), min: RNG.rand(60))
    end.sort.tap { |times| times[-1] = 2.hours.ago }
  end

  # ---------------------------------------------------------------- helpers

  def staff = @staff ||= User.where(email: %w[avo@cado.com maya@example.com tomas@example.com priya@example.com jonas@example.com]).order(:id).to_a
  def customers = User.where.not(id: staff.map(&:id)).order(:id).to_a
  def products = Product.order(:id).to_a
  def warehouses = Warehouse.order(:id).to_a
  def suppliers = Supplier.order(:id).to_a

  def session_for(user)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    if user
      login_as(user, scope: :user)
      # One request first, so Warden stores the user in this session's cookie before the next login_as.
      session.get("/avo")
    end
    session
  end

  def as(user)
    session = session_for(user)
    yield session
  ensure
    logout(:user)
  end

  # Each request a little after the one before, as a person or a client works.
  def hit(session, verb, path, pause: RNG.rand(15..150), **options)
    travel_to(@clock += pause) if @clock
    status = session.public_send(verb, path, **options)
    RESULTS["#{verb} #{status}"] += 1
    PROBLEMS << "#{verb} #{path} => #{status}" if status >= 500
    status
  rescue => error
    PROBLEMS << "#{verb} #{path} raised #{error.class}: #{error.message[0, 200]}"
    nil
  end

  def money(min, max) = format("%.2f", RNG.rand(min..max))

  def product_params(product = nil)
    base = product ? {price: (product.price * (1 + RNG.rand(-0.15..0.15))).to_d.round(-1, half: :up).to_s} : {}
    case RNG.rand(5)
    when 0 then base.merge(quantity: RNG.rand(2..60))
    when 1 then base
    when 2 then {quantity: RNG.rand(2..60), is_featured: RNG.rand < 0.5 ? "1" : "0"}
    when 3 then {description: "#{product&.name || "This product"}, now with #{%w[free shipping a two-year warranty a carrying case].sample(random: RNG)}."}
    else base.merge(category: Product.categories.keys.sample(random: RNG))
    end
  end

  TURBO = {"HTTP_ACCEPT" => "text/vnd.turbo-stream.html, text/html"}.freeze

  def run_action(session, action, ids, resource: "products", **fields)
    hit(session, :post, "/avo/resources/#{resource}/actions?action_id=#{action}",
      params: {fields: {avo_resource_ids: ids.join(","), avo_selected_all: "false", **fields}}, headers: TURBO)
  end

  # ------------------------------------------------------------- the panel

  NEW_PRODUCTS = [
    ["Nothing Phone (2a)", "Nothing", "Phones", 349], ["Kindle Paperwhite", "Amazon", "Computers", 159],
    ["Garmin Forerunner 265", "Garmin", "Wearables", 449], ["Sonos Era 100", "Sonos", "Music players", 249],
    ["Framework Laptop 13", "Framework", "Computers", 1049], ["OnePlus 12", "OnePlus", "Phones", 799],
    ["Oura Ring 4", "Oura", "Wearables", 349], ["Marshall Major V", "Marshall", "Music players", 149]
  ].freeze

  def panel_work(rounds)
    rounds.each do |round|
      author = staff[round % staff.size]
      as(author) do |s|
        hit(s, :get, "/avo/resources/products")
        hit(s, :get, "/avo/resources/products?page=2") if round % 3 == 0
        hit(s, :get, "/avo/resources/users") if round.even?
        hit(s, :get, "/avo/resources/warehouses") if round % 4 == 1

        RNG.rand(1..3).times do
          product = products.sample(random: RNG)
          hit(s, :get, "/avo/resources/products/#{product.id}")
          hit(s, :get, "/avo/resources/products/#{product.id}/edit")
          hit(s, :patch, "/avo/resources/products/#{product.id}", params: {product: product_params(product)})
        end

        if round % 2 == 0
          picks = products.sample(RNG.rand(1..6), random: RNG).map(&:id)
          run_action(s, "Avo::Actions::ChangePrice", picks, price: money(99, 1400), price_currency: "USD")
        end
        run_action(s, "Avo::Actions::Restock", products.select { _1.quantity <= 12 }.sample(3, random: RNG).map(&:id), units: 15) if round % 5 == 2
        run_action(s, "Avo::Actions::AssignProduct", [products.sample(random: RNG).id], user: customers.sample(random: RNG).id) if round % 6 == 3
        run_action(s, "Avo::Actions::Standalone", []) if round == 7

        if round < NEW_PRODUCTS.size
          name, manufacturer, category, price = NEW_PRODUCTS[round]
          hit(s, :get, "/avo/resources/products/new")
          hit(s, :post, "/avo/resources/products", params: {product: {
            name: name, manufacturer: manufacturer, category: category, price: price.to_s, price_currency: "USD",
            quantity: RNG.rand(5..40), description: "#{manufacturer} #{name}.", warehouse_id: warehouses.sample(random: RNG).id,
            sku: "#{manufacturer.first(3).upcase}-#{RNG.rand(10_000..99_999)}", supplier_id: suppliers.sample(random: RNG).id
          }})
        end

        if round % 3 == 1
          user = customers.sample(random: RNG)
          hit(s, :get, "/avo/resources/users/#{user.id}/edit")
          hit(s, :patch, "/avo/resources/users/#{user.id}", params: {user: {last_name: Faker::Name.last_name}})
        end

        if round % 4 == 2
          warehouse = warehouses.sample(random: RNG)
          hit(s, :get, "/avo/resources/warehouses/#{warehouse.id}")
          hit(s, :patch, "/avo/resources/warehouses/#{warehouse.id}", params: {warehouse: {name: "#{warehouse.name.split(" (").first} (#{%w[Bay A Bay B Annex].sample(random: RNG)})"}})
        end

        if round % 3 == 2
          owner = customers.sample(random: RNG)
          item = products.sample(random: RNG)
          hit(s, :post, "/avo/resources/users/#{owner.id}/products", params: {fields: {related_id: item.id}})
          hit(s, :delete, "/avo/resources/users/#{owner.id}/products/#{item.id}") if round % 2 == 0
        end

        if round % 4 == 3 && (order = PurchaseOrder.sent.order(:expected_on).first)
          hit(s, :get, "/avo/resources/purchase_orders/#{order.id}")
          run_action(s, "Avo::Actions::ReceivePurchaseOrder", [order.id], resource: "purchase_orders")
        end

        if round % 6 == 1
          product = products.sample(random: RNG)
          hit(s, :get, "/avo/resources/purchase_orders/new")
          hit(s, :post, "/avo/resources/purchase_orders", params: {purchase_order: {
            number: "PO-2026-#{format("%04d", 200 + round)}", supplier_id: product.supplier_id, product_id: product.id,
            warehouse_id: product.warehouse_id, quantity: [24, 48, 96].sample(random: RNG), status: "sent",
            expected_on: (@clock.to_date + RNG.rand(3..14)).iso8601
          }})
        end

        if round % 5 == 0 && (shipment = Shipment.where(status: %w[packing shipped]).order(:id).first)
          hit(s, :get, "/avo/resources/shipments/#{shipment.id}/edit")
          hit(s, :patch, "/avo/resources/shipments/#{shipment.id}", params: {shipment: shipment.packing? ?
            {status: "shipped", tracking_number: RNG.rand(10**11..10**12 - 1).to_s} : {status: "delivered"}})
        end

        if round % 5 == 3
          product = products.sample(random: RNG)
          hit(s, :post, "/avo/resources/stock_movements", params: {stock_movement: {product_id: product.id,
            warehouse_id: product.warehouse_id, kind: "adjustment", quantity: -RNG.rand(1..3), note: "Cycle count"}})
        end

        if round % 7 == 4
          supplier = suppliers.sample(random: RNG)
          hit(s, :patch, "/avo/resources/suppliers/#{supplier.id}", params: {supplier: {lead_time_days: supplier.lead_time_days + 2}})
        end

        # Recorded before the save runs, so a save that fails validation still leaves an entry.
        hit(s, :patch, "/avo/resources/products/#{products.sample(random: RNG).id}", params: {product: {quantity: ""}}) if round == 4

        if [5, 11].include?(round)
          doomed = Product.where(name: NEW_PRODUCTS.map(&:first)).order(:id).first
          hit(s, :delete, "/avo/resources/products/#{doomed.id}") if doomed
        end
      end
    end
  end

  # Undo an update whose save also recalculated its warehouse, once with the warehouse ticked and once without.
  def undo_work
    candidates = Avo::AuditLogging::Activity.where(action: "update", activity_class: "Avo::Resources::Product")
      .includes(:activity_pivots).order(:id).select { |activity| activity.chained_pivots.any? && activity.primary_pivot&.activity_pivot_id }
    candidates.last(2).each_with_index do |activity, index|
      version_id = activity.primary_pivot.activity_pivot_id
      chained = activity.chained_pivots.map(&:activity_pivot_id).compact.map(&:to_s)
      as(staff[index]) do |s|
        hit(s, :post, "/avo/resources/avo_activities/#{activity.id}/actions", params: {
          action_id: "Avo::Actions::Undo", arguments: Avo::BaseAction.encode_arguments(version_id: version_id),
          resource_view: "show",
          fields: {avo_resource_ids: activity.to_param, avo_selected_all: "false", also_undo: index.zero? ? chained : []}
        }, headers: TURBO)
      end
    end
  end

  # ------------------------------------------------------------------- MCP

  MCP_CLIENTS = [["Claude Code", 1], ["Cursor", 2], ["ChatGPT", 3]].freeze

  def mcp_work(index)
    client_name, staff_index = MCP_CLIENTS[index]
    admin = staff[staff_index]
    token = connect_mcp(admin, client_name)
    return PROBLEMS << "MCP #{client_name}: no token" unless token

    begin

      api = session_for(nil)
      call = ->(tool, arguments) { mcp_call(api, token, tool, arguments) }
      mcp_rpc(api, token, "initialize", {protocolVersion: "2025-06-18", capabilities: {},
        clientInfo: {name: client_name.parameterize, version: "1.0.0"}})
      call.call("list_records", {resource: "Product"})
      product = products.sample(random: RNG)
      call.call("show_record", {resource: "Product", id: product.id.to_s})
      call.call("update_record", {resource: "Product", id: product.id.to_s, attributes: {quantity: product.quantity + 12}})
      second = products.sample(random: RNG)
      call.call("update_record", {resource: "Product", id: second.id.to_s, attributes: {is_featured: !second.is_featured}})
      call.call("run_action", {resource: "Product", action: "Avo::Actions::Restock",
        record_ids: products.sample(2, random: RNG).map { _1.id.to_s }, fields: {units: 10}})
      if index == 0
        call.call("create_record", {resource: "Product", attributes: {name: "Anker 737 Power Bank", manufacturer: "Anker",
          category: "Phones", price: "109.99", quantity: 30, sku: "ANK-73701", description: "Created from Claude Code."}})
      end
      if index == 2 && (late = Shipment.shipped.order(:id).first)
        call.call("update_record", {resource: "Shipment", id: late.id.to_s, attributes: {status: "delivered"}})
      end
      if index == 1
        gone = Product.find_by(name: NEW_PRODUCTS.last.first)
        call.call("delete_record", {resource: "Product", id: gone.id.to_s}) if gone
      end
    end
  end

  def connect_mcp(admin, client_name)
    api = session_for(nil)
    redirect_uri = "http://127.0.0.1:#{33_000 + RNG.rand(999)}/callback"
    hit(api, :post, "/avo/mcp/register", params: {client_name: client_name, application_type: "native",
      redirect_uris: [redirect_uri], token_endpoint_auth_method: "none"}.to_json, headers: {"CONTENT_TYPE" => "application/json"})
    client_id = JSON.parse(api.response.body)["client_id"]

    verifier = SecureRandom.urlsafe_base64(48)
    authorize = {response_type: "code", client_id: client_id, redirect_uri: redirect_uri,
      code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false),
      code_challenge_method: "S256", state: SecureRandom.hex(8), scope: "avo:read avo:write avo:actions",
      resource: "http://localhost/avo/mcp"}
    code = nil
    as(admin) do |s|
      hit(s, :get, "/avo/mcp_server/authorize", params: authorize)
      hit(s, :post, "/avo/mcp_server/authorize", pause: 20, params: authorize.merge(decision: "approve", access: "read_write",
        capabilities: ["avo:actions"], attestation: "1"))
      code = Rack::Utils.parse_query(URI.parse(s.response.location.to_s).query.to_s)["code"]
    end
    return PROBLEMS << "MCP #{client_name}: no code (#{api.response.status})" && nil unless code

    hit(api, :post, "/avo/mcp/token", pause: 2, params: {grant_type: "authorization_code", code: code, code_verifier: verifier,
      redirect_uri: redirect_uri, client_id: client_id})
    JSON.parse(api.response.body)["access_token"]
  end

  def mcp_rpc(session, token, method, params)
    hit(session, :post, "/avo/mcp", params: {jsonrpc: "2.0", id: SecureRandom.hex(4), method: method, params: params}.to_json,
      headers: {"CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json, text/event-stream",
                "HTTP_MCP_PROTOCOL_VERSION" => "2025-06-18", "HTTP_AUTHORIZATION" => "Bearer #{token}"})
    body = JSON.parse(session.response.body) rescue {}
    PROBLEMS << "MCP #{method} #{params[:name]}: #{body["error"] || body.dig("result", "content", 0, "text").to_s[0, 160]}" if body["error"] || body.dig("result", "isError")
    RESULTS["mcp #{params[:name] || method}"] += 1
    body
  end

  def mcp_call(session, token, tool, arguments) = mcp_rpc(session, token, "tools/call", {name: tool, arguments: arguments})

  # ------------------------------------------------------------------- API

  # An ERP that tops stock up and adds products, and a storefront whose sales draw stock down.
  def api_work(index)
    name, owner = [["Inventory sync", staff[4]], ["Storefront", staff[3]]][index]
    token, secret = Avo::Api::Token.generate(name: name, owner: owner)
    token.save!
    api = session_for(nil)
    headers = {"HTTP_AUTHORIZATION" => "Bearer #{secret}", "HTTP_ACCEPT" => "application/json"}
    hit(api, :get, "/api/resources/v1/products", headers: headers)
    products.sample(4, random: RNG).each do |product|
      hit(api, :get, "/api/resources/v1/products/#{product.id}", headers: headers)
      quantity = index.zero? ? product.quantity + RNG.rand(10..30) : RNG.rand(1..6)
      hit(api, :patch, "/api/resources/v1/products/#{product.id}", params: {product: {quantity: quantity}}, headers: headers)
    end
    return unless index.zero?

    hit(api, :post, "/api/resources/v1/products", headers: headers, params: {product: {name: "Logitech MX Master 3S",
      manufacturer: "Logitech", category: "Computers", price: "99.99", price_currency: "USD", quantity: 25, sku: "LOG-30310",
      description: "Synced from the ERP."}})
  end

  # -------------------------------------------------------------------- AI

  def ai_work(index)
    airpods = Product.find_by!(name: "AirPods Max")
    prompts = {
      "Drop the AirPods Max to $499 for the holiday sale" => {
        tool: "update_record", input: {resource: "Product", id: airpods.id.to_s, attributes: [{field: "price", value: 499}]},
        title: "AirPods Max holiday price", after: "Done, the AirPods Max now sell for $499."
      },
      "Add the Bose QuietComfort Earbuds at $299, 20 in stock, in the Central Hub" => {
        tool: "create_record", input: {resource: "Product", attributes: [
          {field: "name", value: "Bose QuietComfort Earbuds"}, {field: "manufacturer", value: "Bose"},
          {field: "category", value: "Music players"}, {field: "price", value: 299}, {field: "quantity", value: 20},
          {field: "description", value: "Bose QuietComfort Earbuds."}, {field: "sku", value: "BOS-58820"}, {field: "warehouse", value: Warehouse.where("name LIKE ?", "Central Hub%").first!.id.to_s}
        ]},
        title: "New Bose earbuds", after: "Added the Bose QuietComfort Earbuds: $299, 20 in stock at the Central Hub."
      }
    }
    prompt = prompts.keys[index]
    user = staff[index * 2]

    FakeLlm.serve(prompts) do |base_url|
      RubyLLM.config.anthropic_api_base = base_url
      RubyLLM.config.anthropic_api_key ||= "seed"

      as(user) do |s|
        hit(s, :post, "/avo/chats", params: {avo_ai_chat: {prompt: prompt, model: FakeLlm::MODEL}})
        chat = Avo::Ai::Chat.where(user: user).order(:id).last
        pending = chat&.pending_writes&.order(:id)&.last
        next unless pending

        message = chat.messages.order(:id).to_a.reverse.find { _1.content.to_s.include?(%("pending_write_id":#{pending.id})) }
        hit(s, :post, "/avo/chats/#{chat.id}/pending_writes/#{pending.id}/confirm", params: {message_id: message&.id})
      end
    ensure
      RubyLLM.config.anthropic_api_base = nil
    end
  end

  # ----------------------------------------------------- outside the panel

  # Jobs run with no signed-in user, so the job is what made each change.
  def jobs_work
    RestockLowStockJob.perform_now(units: 20)
    # The host's own origin, labelled in config.audit_logging.origin_labels.
    SupplierFeedJob.perform_now(warehouses.first, 3)
  end

  # A rake task, the console, and a runner script, each in a process of its own.
  def scripts_work
    rails = [RbConfig.ruby, Rails.root.join("bin/rails").to_s]
    system(*rails, "products:clearance", chdir: Rails.root.to_s, exception: false) || PROBLEMS << "rake products:clearance failed"
    IO.popen([*rails, "console"], "r+", chdir: Rails.root.to_s, err: File::NULL) do |console|
      console.puts %(Product.find_by!(name: "Apple TV 4K (128GB)").update!(quantity: 0, is_featured: false))
      console.puts "exit"
      console.close_write
      console.read
    end
    system(*rails, "runner", %(Product.find_by!(name: "Pixel Watch 3").update!(description: "Discontinued by the manufacturer.")),
      chdir: Rails.root.to_s, exception: false) || PROBLEMS << "runner failed"
  end

  # The app's own sign-up page, outside Avo.
  def sign_up_work
    hit(session_for(nil), :post, "/users", params: {user: {email: "new.reseller@example.com",
      password: "secret123", password_confirmation: "secret123"}})
  end

  # ---------------------------------------------------------------- spread

  def report
    activities = Avo::AuditLogging::Activity.all
    puts "\nRESULTS #{RESULTS.sort.to_h}"
    puts "PROBLEMS #{PROBLEMS.size}"
    PROBLEMS.first(30).each { puts "  #{_1}" }
    puts "ACTIVITIES #{activities.count}"
    puts "  by origin #{activities.group(:origin).count.sort_by { -_2 }.to_h}"
    puts "  by action #{activities.group(:action).count.sort_by { -_2 }.to_h}"
  end
end

ActivitySeed.run
