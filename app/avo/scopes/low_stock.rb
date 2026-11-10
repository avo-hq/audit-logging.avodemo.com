class Avo::Scopes::LowStock < Avo::Scopes::BaseScope
  self.name = "Low stock"
  self.description = "Ten or fewer left"
  self.scope = -> { query.low_stock }
end
