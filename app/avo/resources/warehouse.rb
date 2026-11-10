class Avo::Resources::Warehouse < Avo::BaseResource
  self.audit_logging = {
    activity: true
  }

  def fields
    panel do
      card do
        field :id, as: :id
        field :name, as: :text
        field :inventory_value, as: :money, currencies: %w[USD], readonly: true,
          help: "Recalculated whenever one of its products changes"
      end

      if Avo::AuditLogging.configuration.enabled?
        sidebar do
          tool Avo::ResourceTools::Timeline
        end
      end
    end

    field :products, as: :has_many
  end
end
