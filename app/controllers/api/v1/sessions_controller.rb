class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        message: 'Logged in successfully.',
        token: current_token,
        user: { id: resource.id, username: resource.username, email: resource.email, role: resource.role }
      }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def respond_to_on_destroy
    render json: { message: 'Logged out successfully.' }, status: :ok
  end

  def current_token
    request.env['warden-jwt_auth.token']
  end
end
