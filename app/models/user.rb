class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

   devise :database_authenticatable, :registerable, :recoverable, :validatable, 
          :jwt_authenticatable, jwt_revocation_strategy: self  
  
  #to_do: add role
  enum :role, { admin: 0, user: 1, reader: 2 }

  # Validations cho username
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 3 }
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :password, presence: true, length: { minimum: 6 }
  validates :password_confirmation, presence: true, on: :create

  #callbacks
  before_validation :name_from_username
  before_validation :set_default_role, on: :create
  before_create :generate_jti

  private

  def generate_jti
    self.jti ||= SecureRandom.uuid
  end
  
  def set_default_role
    self.role ||= :user 
  end

  def name_from_username
    self.name ||= self.username
  end
end
