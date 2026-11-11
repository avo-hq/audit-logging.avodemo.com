# == Schema Information
#
# Table name: products
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  description  :text             not null
#  price        :integer          not null
#  quantity     :integer          not null
#  manufacturer :string           not null
#  category     :integer          not null
#  is_featured  :boolean          default(FALSE)
#  user_id      :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Product < ApplicationRecord
  has_paper_trail

  enum :category, {
    "Music players": 0,
    "Phones": 1,
    "Computers": 2,
    "Wearables": 3
  }

  LOW_STOCK = 10

  scope :low_stock, -> { where(quantity: ..LOW_STOCK) }

  belongs_to :warehouse, optional: true
  belongs_to :user, optional: true
  belongs_to :supplier, optional: true
  has_many :stock_movements, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy

  validates_presence_of :quantity
  validates_presence_of :price_cents

  monetize :price_cents

  def assign_to(user)
    self.user = user
    self.save!

    user.update!(updated_at: Time.current)
  end

  def restock!(units, note: "Restock")
    transaction do
      update!(quantity: quantity + units)
      stock_movements.create!(kind: :receipt, quantity: units, warehouse: warehouse, note: note)
    end
  end

  after_update_commit :update_warehouse_value

  def update_warehouse_value
    warehouse&.recalc_total!
  end
end
