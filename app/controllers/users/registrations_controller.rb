class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionsFix
  include JsonRenderable
  respond_to :json

  private

  def respond_with(current_user, _opts = {})
    if resource.persisted?
      render_success status: :created
    else
      render_error errors: "User couldn't be created successfully. #{current_user.errors.full_messages.to_sentence}"
    end
  end
end
