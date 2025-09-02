class User < ApplicationRecord
  has_secure_password

  enum :role, { admin: 0, user: 1, reader: 2 }

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: roles.keys }, allow_nil: true

  before_validation :set_name_if_blank, :set_default_role
  after_validation :log_errors

  before_destroy :check_admin_count
  around_destroy :log_destroy_operation
  after_destroy :notify_users

  private

  def set_name_if_blank
    self.name = username if name.blank?
  end

  def set_default_role
    self.role ||= :user
  end

  def log_errors
    if errors.any?
      Rails.logger.error("User validation errors: #{errors.full_messages.join(", ")}")
    end
  end

  def check_admin_count
    if admin? && User.where(role: roles[:admin]).count == 1
      throw :abort
    end
    Rails.logger.info("Checked the admin count")
  end

  def log_destroy_operation
    Rails.logger.info("Destroying user #{id}")
    yield
    Rails.logger.info("Destroyed user #{id}")
  end

  def notify_users
    Rails.logger.info("Notifying users about the user destruction")
  end
end
