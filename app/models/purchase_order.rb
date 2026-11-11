class PurchaseOrder < ApplicationRecord
  has_paper_trail

  enum :status, {draft: 0, sent: 1, received: 2, cancelled: 3}

  belongs_to :supplier
  belongs_to :warehouse
  belongs_to :product

  validates :number, :quantity, presence: true

  def receive!
    transaction do
      received!
      product.restock!(quantity, note: "Received on #{number}")
    end
  end
end
