class UsersController < ApplicationController
  include Authorizable
  include ErrorHandler

  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :update, :destroy ]
  before_action :authorize_admin!, only: [ :index, :create, :destroy ]

  def index
    users = User.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(users)
    render_success resource: users, meta: meta
  end

  def create
    user = User.new(user_params)
    user.save
    render_success resource: user, status: :created
  end

  def show
    render_success resource: @user
  end

  def update
    if user_params[:role].present? && !current_user.admin?
      render_error("Only admin can change role")
      return
    end

    @user.update(user_params)
    render_success resource: @user
  end

  def destroy
    @user.destroy
    render_success
  end

  private

  def set_user
    @user = User.friendly.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :role, :name, :password_confirmation)
  end

end
