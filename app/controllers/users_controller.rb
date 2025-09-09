# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :update, :destroy ]
  before_action :authorize_user, only: [ :show, :update, :destroy ]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    users = User.all.page(page).per(per_page)
    meta = {
      total_pages: users.total_pages,
      current_page: users.current_page,
      per_page: users.limit_value,
      total_count: users.total_count
    }
    if users.empty?
      render_error message: "No users found", status: :not_found, data: users.as_json
    else
      render_success data: UserSerializer.new(users).serializable_hash[:data], meta: meta
    end
  end

  def create
    user = User.new(user_params)
    if user.save
      render_success data: UserSerializer.new(user).serializable_hash[:data][:attributes], status: :created
    else
      render_error errors: user.errors.full_messages, status: :unprocessable_entity
    end
  end

  def show
    render_success data: UserSerializer.new(@user).serializable_hash[:data][:attributes]
  end

  def update
    if @user.update(user_params)
      render_success data: UserSerializer.new(@user).serializable_hash[:data][:attributes]
    else
      render_error errors: @user.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      render_success message: "User deleted successfully."
    else
      render_error errors: @user.errors.full_messages, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    return if current_user == @user || current_user.admin?

    render_error message: "Unauthorized", status: :unauthorized
  end

  def user_params
    params.require(:user).permit(:email, :password, :role, :name)
  end
end
