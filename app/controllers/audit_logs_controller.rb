class AuditLogsController < ApplicationController
  include Authorizable
  include ErrorHandler
  
  before_action :authenticate_user!
  before_action :set_user, :set_entity_type, :set_action
  before_action :set_audit_log, only: [:show, :destroy]
  before_action :authorize_admin!

  def index
    logs = AuditLog.all
    logs = logs.where(user_id: @user.id) if @user.present?
    logs = logs.where(entity_type: @entity_type) if @entity_type.present?
    logs = logs.where(action: @action_type) if @action_type.present?
    logs = logs.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(logs)
    render_success resource: logs, meta: meta
  end

  def show
    render_success resource: @audit_log
  end

  def destroy
    @audit_log.destroy
    render_success
  end

  private

  def set_user
    @user = User.find_by(id: params[:user_id])
  end

  def set_entity_type
    @entity_type = params[:entity_type] 
  end

  def set_action
    @action_type = params[:action_type]
  end

  def set_audit_log
    @audit_log = AuditLog.find(params[:id])
  end
end
