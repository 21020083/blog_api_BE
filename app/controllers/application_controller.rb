class ApplicationController < ActionController::API
  include JsonRenderable
  before_action :configure_permitted_parameters, if:
  :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name role])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name role])
  end

  private

  def pagination_data(collection)
    {
      total_pages: collection.total_pages,
      current_page: collection.current_page,
      per_page: collection.limit_value,
      total_count: collection.total_count
    }
  end
end
