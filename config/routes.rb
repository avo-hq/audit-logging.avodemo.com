Rails.application.routes.draw do
  root to: redirect(Avo.configuration.root_path)

  devise_for :users

  # Outside the authenticate block: AI clients and API callers bring their own credentials.
  mount_avo_mcp_server
  mount_avo_api

  authenticate :user do
    mount_avo
  end
end

if defined? ::Avo
  Avo::Engine.routes.draw do
    scope :resources do
      get "users/impersonate/:id", to: "users#impersonate", as: :impersonate
      post :stop_impersonating, to: "users#stop_impersonating", as: :stop_impersonating
    end
  end
end