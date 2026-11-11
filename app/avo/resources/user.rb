class Avo::Resources::User < Avo::BaseResource
  # outside_avo logs a sign-up through the app's own Devise pages too.
  self.audit_logging = {
    activity: true,
    outside_avo: true,
    actions: {
      show: false
    }
  }

  self.title = :email

  self.search = {
    query: -> { query.where("first_name LIKE :q OR last_name LIKE :q OR email LIKE :q", q: "%#{params[:q]}%") }
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
        field :name, as: :text, only_on: :index
        field :first_name, as: :text, hide_on: :index
        field :last_name, as: :text, hide_on: :index
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
      field :avo_authored, as: :has_many, name: "Audit log"
    end
  end

  def filters
    filter Avo::Filters::IsAdmin
  end

  def actions
    action Avo::Actions::Impersonate
  end
end
