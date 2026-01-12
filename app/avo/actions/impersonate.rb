class Avo::Actions::Impersonate < Avo::BaseAction
  self.name = "Impersonate"
  self.confirmation = false

  def handle(query:, fields:, current_user:, resource:, **args)
    if query.size > 1
      error "Only 1..."
      return
    end

    redirect_to avo.impersonate_path(user = query.first)
    succeed "#{user.email} is on!"
  end
end
