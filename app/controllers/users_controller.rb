# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :update, :destroy ]
  before_action :is_admin?, only: [ :index, :create, :destroy ]

  def index
    users = User.includes(:blogs).page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(users)
    render_success resource: users, meta: meta
  end

  def create
    user = User.new(user_params)
    if user.save
      render_success resource: user, status: :created
    else
      render_error errors: user.errors.full_messages, status: :unprocessable_entity
    end
  end

  def show
    render_success resource: @user
  end

  def update
    if params[:user][:role].present? && !current_user.admin?
      render_error errors: [ "Unauthorized to change role" ], status: :unauthorized
      return
    end

    if @user.update(user_params)
      render_success resource: @user
    else
      render_error errors: @user.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      render_success resource: @user
    else
      render_error errors: @user.errors.full_messages, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    render_error errors: "User not found", status: :not_found unless @user
  end

  def user_params
    params.require(:user).permit(:email, :password, :role, :name, :password_confirmation)
  end

  def is_admin?
    current_user.admin?
  end
end
