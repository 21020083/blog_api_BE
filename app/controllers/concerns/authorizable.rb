module Authorizable
  extend ActiveSupport::Concern

  included do
    def authorize_owner!(resource = nil)
      allowed = resource.user == current_user
      render_error(errors: "You are not the owner of this resource", status: :unauthorized) unless allowed
    end

    def authorize_admin_owner!(resource = nil)
      allowed = resource.user == current_user || current_user.admin?
      render_error(errors: "You are not authorized to access this resource", status: :unauthorized) unless allowed
    end

    def authorize_admin!
      render_error(errors: "You are not admin", status: :unauthorized) unless current_user.admin?
    end
  end
end
