require 'rails_helper'

RSpec.describe "Blogs API", type: :request do
  let(:user) { create(:user) }

  describe "GET /blogs" do
    before { create_list(:blog, 3, user: user) }

    it "trả về danh sách blog" do
      get "/blogs"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
    end
  end

  describe "POST /blogs" do
    let(:valid_params) { { blog: { title: "Test", body: "Hello", user_id: user.id } } }

    it "tạo blog mới" do
      post "/blogs", params: valid_params
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("Test")
    end

    it "trả lỗi nếu thiếu title" do
      post "/blogs", params: { blog: { body: "No title", user_id: user.id } }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Title can't be blank")
    end
  end
end

