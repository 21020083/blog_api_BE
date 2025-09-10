class BlogSerializer
  include JSONAPI::Serializer
  attributes :id, :title, :content, :status, :slug, :created_at, :updated_at
  belongs_to :user
end
