class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :name, :role

  attribute :blogs do |user|
    user.blogs.map do |b|
      {
        id: b.id,
        title: b.title,
        url: Rails.application.routes.url_helpers.blog_path(b.slug)
      }
    end
  end
end
