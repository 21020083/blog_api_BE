module JsonRenderable
  extend ActiveSupport::Concern

  private

  def render_success(data: {}, message: "Success", status: :ok)
    render json: {
      status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status],
      message: message,
      data: data
    }, status: status
  end

  def render_error(errors: [], message: "Error", status: :unprocessable_entity)
    render json: {
      status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status],
      message: message,
      errors: errors
    }, status: status
  end
end
