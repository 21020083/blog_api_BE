class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  acts_as_voter
  has_many :blogs, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_blogs, through: :bookmarks, source: :blog
  has_many :audit_logs, dependent: :destroy
  has_many :notifications, as: :recipient,class_name: 'Noticed::Notification', dependent: :destroy
  devise :database_authenticatable, :registerable, :recoverable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: self
  enum :role, { admin: 0, user: 1 }

  validates :name, presence: true, length: { minimum: 3 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :jti, presence: true, uniqueness: true
  validates :password, confirmation: true, length: { minimum: 6 }, if: :password_required?

  before_validation :default_role, :set_default_name
  before_validation :set_jti, on: :create

  def self.jwt_revoked?(payload, user)
    user.jti != payload["jti"]
  end

  def self.revoke_jwt(payload, user)
    user.update(jti: SecureRandom.uuid)
  end

  def default_role
    self.role = :user if self.role.blank?
  end

  def set_default_name
    return if self.name.present?
    return unless self.email.present?

    base_name = email.split("@").first.parameterize

    loop do
      random_suffix = SecureRandom.alphanumeric(4).downcase
      candidate = "#{base_name}-#{random_suffix}"
      unless self.class.exists?(name: candidate)
        self.name = candidate
        break
      end
    end
  end

  def set_jti
    self.jti = SecureRandom.uuid if self.jti.blank?
  end

  def password_required?
    new_record? || password.present?
  end

end
