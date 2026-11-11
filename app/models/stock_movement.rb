class StockMovement < ApplicationRecord
  has_paper_trail

  enum :kind, {receipt: 0, sale: 1, transfer: 2, adjustment: 3}

  belongs_to :product
  belongs_to :warehouse, optional: true

  validates :quantity, presence: true
end
