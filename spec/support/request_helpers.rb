module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user)
    # Tạo JWT token cho user
    token = JwtService.encode(user_id: user.id)
    { 'Authorization' => "Bearer #{token}" }
  end

  def authenticated_request(method, path, user, params = {})
    headers = auth_headers(user)
    send(method, path, params: params, headers: headers)
  end

  def expect_json_response
    expect(response.content_type).to include('application/json')
  end

  def expect_success_response
    expect(response).to have_http_status(:success)
  end

  def expect_unauthorized_response
    expect(response).to have_http_status(:unauthorized)
  end

  def expect_not_found_response
    expect(response).to have_http_status(:not_found)
  end

  def expect_unprocessable_entity_response
    expect(response).to have_http_status(:unprocessable_entity)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
