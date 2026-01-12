class Avo::Resources::Product < Avo::BaseResource
  self.audit_logging = {
    activity: -> { params[:skip_activity] != "true" }
  }

  self.title = :name

  def fields
    panel do
      card do
        field :id, as: :id
        field :name, as: :text, filterable: true
        field :manufacturer, as: :text, sortable: true, filterable: {
          type: :select, options: ::Product.all.pluck(:manufacturer).uniq
        }
        field :price, as: :money, currencies: %w[USD]
        field :quantity, as: :number, step: 1
        field :description, as: :trix
        field :is_featured, as: :boolean
        field :category, as: :select, enum: ::Product.categories
        field :warehouse, as: :belongs_to
      end

      if Avo::AuditLogging.configuration.enabled?
        sidebar do
          tool Avo::ResourceTools::Timeline
        end
      end
    end
  end

  def actions
    action Avo::Actions::ChangePrice
    action Avo::Actions::Standalone
    action Avo::Actions::AssignProduct
  end
end
