class Avo::Actions::ReceivePurchaseOrder < Avo::BaseAction
  self.name = "Mark received"

  self.audit_logging = {
    activity: true
  }

  def handle(query:, **)
    orders = query.select(&:sent?)
    orders.each(&:receive!)
    succeed "Received #{orders.size} #{"order".pluralize(orders.size)}"
  end
end
