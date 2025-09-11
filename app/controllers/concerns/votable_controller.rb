module VotableController
  extend ActiveSupport::Concern

  included do
    before_action :set_votable, only: [ :upvote, :downvote, :remove_vote ]
  end

  def upvote
    current_user.likes @votable
    render_success resource: @votable
  end

  def downvote
    current_user.dislikes @votable
    render_success resource: @votable
  end

  def remove_vote
    current_user.unlike @votable
    current_user.undislike @votable
    render_success resource: @votable
  end

  private

  def set_votable
    @votable = controller_name.classify.constantize.find(params[:id])
  end
end
