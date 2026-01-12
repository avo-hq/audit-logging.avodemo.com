class Avo::Resources::User < Avo::BaseResource
  self.audit_logging = {
    activity: true,
    actions: {
      show: false
    }
  }

  self.row_controls = -> {
    action Avo::Actions::Impersonate, label: "Impersonate #{record.name}", style: :primary, color: :blue,
    icon: "heroicons/outline/identification"
    show_button
    edit_button
    delete_button
  }

  def fields
    panel do
      card do
        field :id, as: :id, link_to_record: true
        field :email, as: :text, link_to_record: true
      end
      
      if Avo::AuditLogging.configuration.enabled?
        sidebar do
          tool Avo::ResourceTools::Timeline
        end
      end
    end
    
    field :products, as: :has_many

    if Avo::AuditLogging.configuration.enabled?
      field :avo_authored, as: :has_many, name: "Activity"
    end
  end

  def filters
    filter Avo::Filters::IsAdmin
  end

  def actions
    action Avo::Actions::Impersonate
  end
end
