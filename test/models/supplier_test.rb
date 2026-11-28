require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  setup do
    @northwind = Supplier.create!(name: "Northwind Electronics")
    @bluewater = Supplier.create!(name: "Bluewater Distribution")
  end

  test "a new supplier is called last" do
    assert_equal [1, 2], [@northwind.position, @bluewater.position]
    assert_equal 3, Supplier.create!(name: "Kestrel Trading").position
  end

  test "a position given on create is kept" do
    assert_equal 7, Supplier.create!(name: "Kestrel Trading", position: 7).position
  end

  test "a new supplier moves up and down one place at a time" do
    kestrel = Supplier.create!(name: "Kestrel Trading")

    kestrel.insert_at(kestrel.position - 1)
    assert_equal [@northwind, kestrel, @bluewater], Supplier.order(:position).to_a

    kestrel.insert_at(kestrel.position + 1)
    assert_equal [@northwind, @bluewater, kestrel], Supplier.order(:position).to_a
  end

  test "the suppliers after one that goes close up" do
    kestrel = Supplier.create!(name: "Kestrel Trading")
    @northwind.destroy!

    assert_equal [1, 2], [@bluewater.reload.position, kestrel.reload.position]
  end
end
