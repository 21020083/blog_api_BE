module JsonRenderable
  extend ActiveSupport::Concern

  private

  def render_success(resource: nil, include: [], meta: nil, status: :ok)
    payload = { status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] }
  
    if resource
      serializer_class =
        resource.respond_to?(:klass) ? resource.klass.name + "Serializer" : resource.class.name + "Serializer"
      payload.merge!(serializer_class.constantize.new(resource, include: include, meta: meta).serializable_hash)
    else
      payload[:data] = {}
    end
  
    render json: payload, status: status
  end
  


  def render_error(errors:, status: :unprocessable_entity)
    formatted_errors = Array(errors).map do |error|
      {
        status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status].to_s,
        detail: error
      }
    end

    render json: { errors: formatted_errors },
           status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
  end
end
