module JsonRenderable
  extend ActiveSupport::Concern

  private

  def render_success(resource: nil, include: [], meta: nil, status: :ok)
    payload = { status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] }

    if resource.present?
      serializer_class = serializer_for(resource)

      if serializer_class
        payload.merge!(
          serializer_class.new(resource, include: include, meta: meta).serializable_hash
        )
      else
        payload[:data] = resource.as_json
      end
    else
      payload[:data] = nil
    end

    render json: payload, status: status
  end

  private

  def serializer_for(resource)
    klass = resource.respond_to?(:klass) ? resource.klass : resource.class
    "#{klass.name}Serializer".safe_constantize
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
