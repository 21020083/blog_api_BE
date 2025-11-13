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
    # Check if collection is Kaminari paginated
    if collection.respond_to?(:total_pages)
      {
        total_pages: collection.total_pages,
        current_page: collection.current_page,
        per_page: collection.limit_value,
        total_count: collection.total_count
      }
    else
      # For regular ActiveRecord::Relation
      total_count = collection.count
      per_page = collection.limit || total_count
      {
        total_count: total_count,
        per_page: per_page
      }
    end
  end
end
