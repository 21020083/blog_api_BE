class JwtService
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret).first
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.secret
    Rails.application.config.jwt_secret
  end
end
