class BookmarkSerializer
  include JSONAPI::Serializer

  set_type :bookmark
  attributes :user_id, :created_at

  attribute :blog do |object|
    {
      id: object.blog.id,
      title: object.blog.title,
      url: Rails.application.routes.url_helpers.blog_path(object.blog.slug),
      arasuji: object.blog.summary
    }
  end
end
