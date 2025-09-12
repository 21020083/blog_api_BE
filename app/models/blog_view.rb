class BlogView < ApplicationRecord
  belongs_to :blog, counter_cache: :views_count
  belongs_to :user, optional: true

  validates :blog_id, presence: true
  validates :viewed_at, presence: true

  before_validation :set_viewed_at

  scope :recent, ->(timeframe = 1.hour.ago) { where("viewed_at >= ?", timeframe) }
  scope :today, -> { where("DATE(viewed_at) = ?", Date.today) }
  scope :unique_users, -> { where.not(user_id: nil).select(:user_id).distinct }

  def self.trending(limit = 10)
    recent
      .group(:blog_id)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(limit)
      .count
  end

  private

  def set_viewed_at
    self.viewed_at = Time.current
  end
end
