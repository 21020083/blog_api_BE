require 'rails_helper'

RSpec.describe "Authentication API", type: :request do
  describe "POST /signup" do
    it "creates a new user" do
      user_params = {
        user: {
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "John Doe"
        }
      }

      post "/signup", params: user_params

      expect_success_response
      expect_json_response
      expect(json_response['data']['attributes']['email']).to eq("test@example.com")
    end

    it "returns error when email is invalid" do
      user_params = {
        user: {
          email: "invalid-email",
          password: "password123",
          password_confirmation: "password123",
          name: "John Doe"
        }
      }

      post "/signup", params: user_params

      expect_unprocessable_entity_response
      expect_json_response
      expect(json_response['errors']).to be_present
    end

    it "returns error when password confirmation doesn't match" do
      user_params = {
        user: {
          email: "test@example.com",
          password: "password123",
          password_confirmation: "different_password",
          name: "John Doe"
        }
      }

      post "/signup", params: user_params

      expect_unprocessable_entity_response
      expect_json_response
      expect(json_response['errors']).to be_present
    end
  end

  describe "POST /login" do
    let(:user) { create(:user, email: "test@example.com", password: "password123") }

    it "logs in with valid credentials" do
      login_params = {
        user: {
          email: "test@example.com",
          password: "password123"
        }
      }

      post "/login", params: login_params

      expect_success_response
      expect_json_response
      expect(json_response['data']['attributes']['email']).to eq("test@example.com")
    end

    it "returns error with invalid email" do
      login_params = {
        user: {
          email: "wrong@example.com",
          password: "password123"
        }
      }

      post "/login", params: login_params

      expect_unauthorized_response
    end

    it "returns error with invalid password" do
      login_params = {
        user: {
          email: "test@example.com",
          password: "wrong_password"
        }
      }

      post "/login", params: login_params

      expect_unauthorized_response
    end
  end

  describe "DELETE /logout" do
    let(:user) { create(:user, :confirmed) }

    context "when user is authenticated" do
      it "logs out successfully" do
        authenticated_request(:delete, "/logout", user)

        expect_success_response
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        delete "/logout"

        expect_unauthorized_response
      end
    end
  end
end
