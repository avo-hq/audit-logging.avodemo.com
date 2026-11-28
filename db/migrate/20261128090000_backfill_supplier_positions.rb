# Suppliers made outside the seed had no position: they listed above the first one, and their arrows raised. Every
# supplier is numbered again from 1 in the order the list shows them, with those last, oldest first.
class BackfillSupplierPositions < ActiveRecord::Migration[7.2]
  def up
    ids = select_values("SELECT id FROM suppliers ORDER BY position IS NULL, position, id")
    ids.each.with_index(1) { |id, position| execute "UPDATE suppliers SET position = #{position} WHERE id = #{id.to_i}" }
  end

  def down
  end
end
