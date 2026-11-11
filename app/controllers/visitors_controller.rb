# The demo's front door: a name is all it asks for. See User.visitor.
class VisitorsController < ApplicationController
  # Anyone can reach this, and every call makes an account.
  rate_limit to: 5, within: 1.minute, only: :create

  def create
    # No name: the front door comes back with one picked for them, to take or to replace.
    return redirect_to new_user_session_path(nameless: true) if params[:name].blank?

    sign_in User.visitor(params[:name])
    redirect_to Avo.configuration.root_path
  end
end
