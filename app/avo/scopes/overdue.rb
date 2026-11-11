class Avo::Scopes::Overdue < Avo::Scopes::BaseScope
  self.name = "Overdue"
  self.description = "Sent, and past the date the supplier promised"
  self.scope = -> { query.sent.where(expected_on: ...Date.current) }
end
