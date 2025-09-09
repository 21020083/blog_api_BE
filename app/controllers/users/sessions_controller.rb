class Users::SessionsController < Devise::SessionsController
  include RackSessionsFix
  include JsonRenderable
  respond_to :json

  private

  def respond_with(current_user, _opts = {})
    render_success data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
  end

  def respond_to_on_destroy
    return render_error message: "Authorization header missing" unless request.headers["Authorization"].present?

    token = request.headers["Authorization"].split(" ").last
    begin
      jwt_payload = JwtService.decode(token)
      user = User.find(jwt_payload["sub"])
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      return render_error message: "Couldn't find an active session."
    end

    render_success
  end
end
