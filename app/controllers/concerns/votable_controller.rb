module VotableController
  extend ActiveSupport::Concern

  included do
    before_action :set_votable, only: [ :upvote, :downvote, :remove_vote ]
  end

  def upvote
    already_upvoted = current_user.voted_up_on?(@votable)
    current_user.likes(@votable)
    UserMailer.with(votable: @votable, voter: current_user, vote_flag: true).reaction_email.deliver_later
    render_success resource: @votable
  end

  def downvote
    already_downvoted = current_user.voted_down_on?(@votable)
    current_user.dislikes(@votable)
    UserMailer.with(votable: @votable, voter: current_user, vote_flag: false).reaction_email.deliver_later
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
