class Users::SessionsController < Devise::SessionsController
  include RackSessionsFix
  include JsonRenderable
  respond_to :json

  private

  def respond_with(current_user, _opts = {})
    render_success message: "Logged in successfully.", data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
  end

  def respond_to_on_destroy
    if request.headers["Authorization"].present?
      jwt_payload = JwtService.decode(request.headers["Authorization"].split(" ").last)
      current_user = User.find(jwt_payload["sub"])
    end

    if current_user
      render_success message: "Logged out successfully."
    else
      render_error message: "Couldn't find an active session."
    end
  end
end
