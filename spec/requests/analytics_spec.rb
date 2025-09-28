require 'rails_helper'

RSpec.describe "Analytics API", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let!(:blogs) { create_list(:blog, 5, user: user, category: category) }

  describe "GET /analytics/top_views" do
    it "returns blogs with most views" do
      # Simulate some views
      blogs.first.update(views_count: 100)
      blogs.second.update(views_count: 50)
      blogs.third.update(views_count: 25)

      get "/analytics/top_views"

      expect_success_response
      expect_json_response
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].first['attributes']['views_count']).to eq(100)
    end

    it "returns limited number of results" do
      get "/analytics/top_views", params: { limit: 3 }

      expect_success_response
      expect_json_response
      expect(json_response['data'].length).to be <= 3
    end
  end

  describe "GET /analytics/top_likes" do
    it "returns blogs with most likes" do
      # Simulate some votes
      blogs.first.liked_by user
      blogs.second.liked_by user
      blogs.third.liked_by user
      blogs.first.liked_by create(:user) # Add another like

      get "/analytics/top_likes"

      expect_success_response
      expect_json_response
      expect(json_response['data']).to be_an(Array)
    end

    it "returns limited number of results" do
      get "/analytics/top_likes", params: { limit: 2 }

      expect_success_response
      expect_json_response
      expect(json_response['data'].length).to be <= 2
    end
  end
end
