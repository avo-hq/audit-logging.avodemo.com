class Supplier < ApplicationRecord
  has_paper_trail

  has_many :products
  has_many :purchase_orders

  validates :name, presence: true

  # The order the team calls them in. A short list, so a move renumbers every supplier.
  def insert_at(target)
    list = Supplier.where.not(id: id).order(:position).to_a
    list.insert((target.to_i - 1).clamp(0, list.size), self)
    transaction do
      list.each.with_index(1) { |supplier, index| supplier.update!(position: index) unless supplier.position == index }
    end
  end
end
