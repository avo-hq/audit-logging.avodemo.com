class Avo::Scopes::Featured < Avo::Scopes::BaseScope
  self.name = "Featured"
  self.scope = -> { query.where(is_featured: true) }
end
