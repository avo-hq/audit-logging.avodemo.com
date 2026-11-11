class Avo::Actions::Restock < Avo::BaseAction
  self.name = "Restock"

  self.audit_logging = {
    activity: true
  }

  def fields
    field :units, as: :number, default: 25, help: "Units to add to each product"
  end

  def handle(query:, fields:, **)
    query.each { |product| product.restock!(fields[:units].to_i) }
    succeed "Restocked #{query.size} #{"product".pluralize(query.size)}"
  end
end
