module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :entity

    attr_accessor :current_audit_user

    after_create  { log_audit("create") }
    after_update  { log_audit("update") }
    after_destroy { log_audit("destroy") }
  end

  private

  def log_audit(action)
    AuditLog.create(
      user: current_audit_user || (respond_to?(:user) ? self.user : nil),
      action: action,
      entity: self
    )
  end
end
