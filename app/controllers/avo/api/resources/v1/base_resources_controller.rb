module Avo
  module Api
    module Resources
      module V1
        class BaseResourcesController < ResourcesController
          # CSRF protection configuration
          # Override self.setup_csrf_protection method in subclasses to customize CSRF handling
          #
          # Examples:
          #   def self.setup_csrf_protection
          #     protect_from_forgery with: :exception
          #   end

          # Authentication configuration
          # Override setup_authentication method to customize authentication handling
          #
          # Examples:
          #   def setup_authentication
          #     authenticate_with_http_basic do |email, password|
          #       user = User.find_by(email: email)
          #       if user&.valid_password?(password)
          #         sign_in(user, store: false)
          #       else
          #         raise Avo::Api::AuthenticationError
          #       end
          #     end
          #   end
          #
          #   def setup_authentication
          #     # No authentication required - leave empty
          #     super
          #   end

          # Override to customize record serialization globally
          # def serialize_record(resource, view)
          #   result = super(resource, view)
          #   result[:custom_field] = "custom_value"
          #   result
          # end

          # Override to customize success/error responses globally
          # def create_success_action
          #   render json: {
          #     record: serialize_record(@resource, :show),
          #     message: "Successfully created #{@resource.singular_name}"
          #   }, status: :created
          # end
        end
      end
    end
  end
end
