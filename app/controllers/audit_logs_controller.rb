class AuditLogsController < ApplicationController
  include Authorizable
  before_action :authenticate_user!
  before_action :set_user, :set_entity, only: [ :index, :user_logs ]
  before_action :authorize_admin!, only: [ :index, :user_logs ]

  def index
    logs = AuditLog.all
    logs = logs.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(logs)
    render_success resource: logs.order(created_at: :desc), meta: meta
  end

  def user_logs
    logs = AuditLog.where(user_id: @user.id)
    render_success resource: logs.order(created_at: :desc)
  end

  private


  def set_user
    @user = User.find_by(id: params[:user_id])
  end

  def set_entity
    @entity = params[:entity_type]
  end
end
