module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from ActiveRecord::RecordNotDestroyed, with: :render_unprocessable_entity
  end

  private

  def render_not_found(exception = nil)
    message = exception&.message || "Resource not found"
    render_error errors: message, status: :not_found
end

  def render_unprocessable_entity(exception)
    messages = exception.respond_to?(:record) ? exception.record.errors.full_messages : [ exception.message ]
    render_error errors: messages, status: :unprocessable_entity
  end
end
