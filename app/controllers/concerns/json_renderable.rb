module JsonRenderable
  extend ActiveSupport::Concern

  private

  def render_success(resource: nil, meta: nil, status: :ok, serializer: nil, each_serializer: nil, include: [])
    payload = { status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] }

    if resource.present?
      serializer_class = serializer || serializer_for(resource)

      if serializer_class
        options = { include: include, meta: meta }
        options[:each_serializer] = each_serializer if each_serializer
        payload.merge!(
          serializer_class.new(resource, **options).serializable_hash
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
    code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status.to_sym] || 422
    formatted_errors = Array(errors).map do |error|
      {
        status: code.to_s,
        detail: error
      }
    end

    render json: { errors: formatted_errors },
           status: code
  end
end
