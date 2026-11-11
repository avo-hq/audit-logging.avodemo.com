class Avo::Resources::Supplier < Avo::BaseResource
  self.audit_logging = {
    activity: true
  }

  self.search = {query: -> { query.where("name LIKE ?", "%#{params[:q]}%") }}

  self.default_sort_column = :position
  self.default_sort_direction = :asc
  self.ordering = {
    visible_on: :index,
    display_inline: true,
    drag_and_drop: true,
    actions: {
      higher: -> { record.insert_at(record.position - 1) },
      lower: -> { record.insert_at(record.position + 1) },
      insert_at: -> { record.insert_at(position) }
    }
  }

  def fields
    panel do
      card do
        field :id, as: :id
        field :name, as: :text, link_to_record: true
        field :contact_email, as: :text
        field :country, as: :text, filterable: {type: :select, options: -> { ::Supplier.distinct.order(:country).pluck(:country) }}
        field :lead_time_days, as: :number, name: "Lead time (days)"
      end

      sidebar do
        tool Avo::ResourceTools::Timeline
      end
    end

    field :products, as: :has_many
    field :purchase_orders, as: :has_many
  end
end
