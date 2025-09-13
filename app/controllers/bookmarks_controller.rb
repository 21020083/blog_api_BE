class BookmarksController < ApplicationController
  include Authorizable
  include ErrorHandler
  before_action :authenticate_user!
  before_action :set_bookmark, only: [ :destroy ]
  before_action -> { authorize_owner!(@bookmark) }, only: [ :destroy ]

  def index
    bookmarks = current_user.bookmarks.includes(:blog)
                         .page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(bookmarks)
    render_success resource: bookmarks, meta: meta, each_serializer: BookmarkSerializer
  end

  def create
    bookmark = current_user.bookmarks.create!(bookmark_params)
    render_success resource: bookmark, status: :created
  end

  def destroy
    @bookmark.destroy!
    render_success
  end

  private

  def set_bookmark
    @bookmark = current_user.bookmarks.find(params[:id])
  end

  def bookmark_params
    params.require(:bookmark).permit(:blog_id)
  end
end
