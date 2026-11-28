class Avo::Actions::Restock < Avo::BaseAction
  self.name = "Restock"

  self.audit_logging = {
    activity: true
  }

  def fields
    field :units, as: :number, default: 25, min: 1, step: 1, help: "Units to add to each product"
  end

  def handle(query:, fields:, **)
    units = fields[:units].to_i
    # A restock only adds. Checked here as well as on the form, because MCP and the AI chat run it without the form.
    return error("Enter how many units to add, 1 or more").keep_modal_open unless units.positive?

    query.each { |product| product.restock!(units) }
    succeed "Restocked #{query.size} #{"product".pluralize(query.size)}"
  end
end
