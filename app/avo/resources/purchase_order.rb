class Avo::Resources::PurchaseOrder < Avo::BaseResource
  self.audit_logging = {
    activity: true
  }

  self.title = :number
  self.default_sort_column = :expected_on

  def fields
    panel do
      card do
        field :id, as: :id
        field :number, as: :text, link_to_record: true
        field :supplier, as: :belongs_to
        field :product, as: :belongs_to
        field :quantity, as: :number
        field :warehouse, as: :belongs_to, name: "Deliver to"
        field :status, as: :badge, options: {info: :sent, success: :received, neutral: :draft, danger: :cancelled},
          filterable: {type: :select, options: ::PurchaseOrder.statuses.keys, pinned: true}
        field :status, as: :select, enum: ::PurchaseOrder.statuses, only_on: :forms
        field :expected_on, as: :date, sortable: true
      end

      sidebar do
        tool Avo::ResourceTools::Timeline
      end
    end
  end

  def scopes
    scope Avo::Scopes::Overdue
  end

  def actions
    action Avo::Actions::ReceivePurchaseOrder
  end
end
