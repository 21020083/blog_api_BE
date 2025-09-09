module JsonRenderable
  extend ActiveSupport::Concern

  private

  def render_success(data: nil, meta: nil, status: :ok)
    response = { success: true }
    response[:data] = data if data
    response[:meta] = meta if meta
    render json: response, status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
  end

  def render_error(message: nil, errors: nil, status: :unprocessable_entity, data: nil)
    response = { success: false }
    response[:message] = message if message
    response[:errors] = errors if errors
    response[:data] = data if data
    render json: response, status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
  end
end
