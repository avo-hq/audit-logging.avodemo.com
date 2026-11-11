class Avo::Resources::Product < Avo::BaseResource
  # outside_avo logs what jobs, rake tasks and the console change too, not only the panel.
  self.audit_logging = {
    activity: true,
    outside_avo: true
  }

  self.title = :name

  # Global search finds a product by what a storekeeper would type: its name, its SKU or who makes it.
  self.search = {
    query: -> { query.where("name LIKE :q OR sku LIKE :q OR manufacturer LIKE :q", q: "%#{params[:q]}%") }
  }

  # Restock is what the team runs most, so it gets its own button beside Edit.
  self.show_controls = -> do
    back_button
    delete_button
    actions_list exclude: [Avo::Actions::Restock]
    action Avo::Actions::Restock, style: :outline, icon: "heroicons/outline/arrow-down-tray"
    edit_button
  end

  def fields
    panel do
      card do
        field :id, as: :id
        field :name, as: :text, filterable: true
        field :sku, as: :text, name: "SKU"
        field :manufacturer, as: :text, sortable: true, filterable: {
          type: :select, options: -> { ::Product.distinct.order(:manufacturer).pluck(:manufacturer) }, pinned: true
        }
        field :price, as: :money, currencies: %w[USD]
        field :quantity, as: :number, step: 1, filterable: true
        field :description, as: :trix
        field :is_featured, as: :boolean, filterable: {pinned: true}
        field :category, as: :select, enum: ::Product.categories, filterable: {pinned: true}
        field :warehouse, as: :belongs_to
        field :supplier, as: :belongs_to
        field :user, as: :belongs_to, name: "Owner"
      end

      if Avo::AuditLogging.configuration.enabled?
        sidebar do
          tool Avo::ResourceTools::Timeline
        end
      end
    end

    # A new product's first delivery is logged on the same form.
    field :stock_movements, as: :has_many, nested: {on: :new, limit: 3}
    field :avo_activities, as: :has_many, name: "Activity" if Avo::AuditLogging.configuration.enabled?
  end

  def scopes
    scope Avo::Scopes::LowStock
    scope Avo::Scopes::Featured
  end

  def actions
    action Avo::Actions::ChangePrice
    action Avo::Actions::Restock
    action Avo::Actions::AssignProduct
    action Avo::Actions::Standalone
  end
end
