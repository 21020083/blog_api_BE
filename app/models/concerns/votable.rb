module Votable
  extend ActiveSupport::Concern

  included do
    acts_as_votable
  end

  def get_likes_count
    get_likes.size
  end

  def get_dislikes_count
    get_dislikes.size
  end
end
