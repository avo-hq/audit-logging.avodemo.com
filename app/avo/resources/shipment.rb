class Avo::Resources::Shipment < Avo::BaseResource
  self.audit_logging = {
    activity: true
  }

  self.title = :reference

  def fields
    panel do
      card do
        field :id, as: :id
        field :reference, as: :text, link_to_record: true
        field :warehouse, as: :belongs_to, name: "From"
        field :destination, as: :text
        field :carrier, as: :text, filterable: {type: :select, options: -> { ::Shipment.distinct.order(:carrier).pluck(:carrier) }}
        field :tracking_number, as: :text, hide_on: :index
        field :status, as: :badge, options: {info: :shipped, success: :delivered, warning: :packing, danger: :returned},
          filterable: {type: :select, options: ::Shipment.statuses.keys, pinned: true}
        field :status, as: :select, enum: ::Shipment.statuses, only_on: :forms
        field :shipped_at, as: :date_time, sortable: true
      end

      sidebar do
        tool Avo::ResourceTools::Timeline
      end
    end
  end
end
