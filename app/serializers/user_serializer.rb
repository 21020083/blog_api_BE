class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :username, :email, :name, :role

  attribute :token do |object, params|
    params[:token]
  end
end
