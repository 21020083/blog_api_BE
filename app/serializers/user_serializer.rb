class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :name, :role

  has_many :blogs, serializer: BlogSerializer
end
