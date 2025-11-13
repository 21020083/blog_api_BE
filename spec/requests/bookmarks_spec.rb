require 'rails_helper'

RSpec.describe "Bookmarks API", type: :request do
  let(:user) { create(:user) }
  let(:blog) { create(:blog, user: user) }
  let(:bookmark) { create(:bookmark, user: user, blog: blog) }

  describe "GET /bookmarks" do
    context "when user is authenticated" do
      it "returns user's bookmarks" do
        bookmark # Create the bookmark
        authenticated_request(:get, "/bookmarks", user)

        expect_success_response
        expect_json_response
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].length).to eq(1)
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/bookmarks"

        expect_unauthorized_response
      end
    end
  end

  describe "POST /bookmarks" do
    context "when user is authenticated" do
      it "creates a new bookmark" do
        bookmark_params = {
          bookmark: {
            blog_id: blog.id
          }
        }

        authenticated_request(:post, "/bookmarks", user, bookmark_params)

        expect_success_response
        expect_json_response
        expect(json_response['data']['attributes']['blog_id']).to eq(blog.id)
      end

      it "returns error when blog_id is invalid" do
        bookmark_params = {
          bookmark: {
            blog_id: 99999
          }
        }

        authenticated_request(:post, "/bookmarks", user, bookmark_params)

        expect_unprocessable_entity_response
        expect_json_response
        expect(json_response['errors']).to be_present
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        bookmark_params = {
          bookmark: {
            blog_id: blog.id
          }
        }

        post "/bookmarks", params: bookmark_params

        expect_unauthorized_response
      end
    end
  end

  describe "DELETE /bookmarks/:id" do
    context "when user is authenticated" do
      it "deletes a bookmark" do
        authenticated_request(:delete, "/bookmarks/#{bookmark.id}", user)

        expect_success_response
        expect(Bookmark.find_by(id: bookmark.id)).to be_nil
      end

      it "returns not found for non-existent bookmark" do
        authenticated_request(:delete, "/bookmarks/99999", user)

        expect_not_found_response
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        delete "/bookmarks/#{bookmark.id}"

        expect_unauthorized_response
      end
    end
  end
end
