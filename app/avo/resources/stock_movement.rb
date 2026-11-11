class Avo::Resources::StockMovement < Avo::BaseResource
  self.audit_logging = {
    activity: true
  }

  def fields
    field :id, as: :id
    field :created_at, as: :date_time, name: "When", only_on: :display, sortable: true
    field :product, as: :belongs_to
    field :warehouse, as: :belongs_to
    field :kind, as: :select, enum: ::StockMovement.kinds, filterable: {pinned: true}
    field :quantity, as: :number
    field :note, as: :text
  end
end
