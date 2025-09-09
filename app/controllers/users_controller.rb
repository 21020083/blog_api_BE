# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!, except: [ :create ]
  def index
      users = User.all
      render json: { users: users }
  end

  def create
    user = User.new(user_params)
    if user.save
      render json: { user: user, token: generate_jwt(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render json: { user: @user }
  end

  def update
    if @user.update(user_params)
      render json: { user: @user }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @user.soft_delete
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    unless current_user == @user || current_user.admin?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :role, :name)
  end
end
