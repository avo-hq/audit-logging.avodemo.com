# For more information regarding these settings check out our docs https://docs.avohq.io
Avo.configure do |config|
  ## == Routing ==
  config.root_path = "/avo"

  ## == Licensing ==
  config.license_key = ENV["AVO_LICENSE_KEY"]
  config.exclude_from_status = ["license_key"]

  ## == Authentication ==
  config.current_user_method = :current_user

  ## == Authorization ==
  # No authorization client: every signed-in user may see and do everything, which is what a public demo wants.
  config.authorization_client = nil
  config.explicit_authorization = true

  ## == Customization ==
  config.app_name = "Stockroom"
  config.container_width = :full
  config.click_row_to_view_record = true

  config.turbo = -> do
    {
      instant_click: false
    }
  end

  ## == Audit logging ==
  config.audit_logging.enabled = true

  ## == Dynamic filters ==
  config.dynamic_filters.simple_filters = true
  config.dynamic_filters.inline_filters = true

  ## == MCP server ==
  config.mcp_server.enabled = true

  ## == Avo AI ==
  config.ai.empty_state_suggestions = [
    "Which products are running low on stock?",
    "Raise the price of every Sony product by 5%",
    "What changed in the North Warehouse this week?"
  ]

  ## == Menus ==
  config.main_menu = -> {
    section "Catalog", icon: "tabler/outline/tag" do
      resource :product
      resource :supplier
    end

    section "Inventory", icon: "tabler/outline/building-warehouse" do
      resource :warehouse
      resource :stock_movement
    end

    section "Orders", icon: "tabler/outline/truck" do
      resource :purchase_order
      resource :shipment
    end

    section "Team", icon: "tabler/outline/users" do
      resource :user
    end

    if Avo::AuditLogging.configuration.enabled?
      section "Audit log", icon: "presentation-chart-bar" do
        resource :avo_activity
      end
    end

    section "Integrations", icon: "plug-connected" do
      resource :mcp_connection
      resource "avo_api/tokens"
    end

    section "AI", icon: "heroicons/outline/sparkles" do
      resource "avo_ai/chats"
      resource "avo_ai/messages"
      resource "avo_ai/models"
      resource "avo_ai/skills"
    end
  }

  config.profile_menu = -> {
    # The way back to the guided tour, also after "Don't ask again".
    link_to "Take the tour", path: "#{config.root_path}/resources/products?tour=1", icon: "tabler/outline/map-pin"
    link_to "Stop impersonating", path: Avo::Engine.routes.url_helpers.stop_impersonating_path, icon: "user-circle", method: :post
  }
end

Rails.configuration.to_prepare do
  Avo::ApplicationController.include UsePretender
end
