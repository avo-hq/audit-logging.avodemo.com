class Supplier < ApplicationRecord
  has_paper_trail

  has_many :products
  has_many :purchase_orders

  validates :name, presence: true

  # A supplier's position is its place in the call order, counted from 1: the panel's arrows move it by one. One added
  # in the panel, over MCP, the API or the chat is called last, and the ones after a supplier that goes close up.
  before_create { self.position ||= Supplier.maximum(:position).to_i + 1 }
  after_destroy :close_up, if: :position

  # The order the team calls them in. A short list, so a move renumbers every supplier.
  def insert_at(target)
    list = Supplier.where.not(id: id).order(:position).to_a
    list.insert((target.to_i - 1).clamp(0, list.size), self)
    transaction do
      list.each.with_index(1) { |supplier, index| supplier.update!(position: index) unless supplier.position == index }
    end
  end

  private

  def close_up
    Supplier.where("position > ?", position).each { |supplier| supplier.update!(position: supplier.position - 1) }
  end
end
