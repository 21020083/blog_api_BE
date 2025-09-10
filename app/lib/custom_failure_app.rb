class CustomFailureApp < Devise::FailureApp
  def respond
      json_error_response
  end

  def json_error_response
    self.status = 401
    self.content_type = "application/json"
    self.response_body = { error: "Unauthorized", message: i18n_message }.to_json
  end
end
