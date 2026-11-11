class Supplier < ApplicationRecord
  has_paper_trail

  has_many :products
  has_many :purchase_orders

  validates :name, presence: true
end
