class Shipment < ApplicationRecord
  has_paper_trail

  enum :status, {packing: 0, shipped: 1, delivered: 2, returned: 3}

  belongs_to :warehouse

  validates :reference, :carrier, :destination, presence: true
end
