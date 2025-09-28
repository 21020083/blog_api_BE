require 'rails_helper'

RSpec.describe "Comments API", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:blog) { create(:blog, user: user) }
  let(:comment) { create(:comment, user: user, blog: blog) }

  describe "POST /blogs/:blog_id/comments" do
    context "when user is authenticated" do
      it "creates a new comment" do
        comment_params = {
          comment: {
            comment_text: "This is a test comment"
          }
        }

        authenticated_request(:post, "/blogs/#{blog.id}/comments", user, comment_params)

        expect_success_response
        expect_json_response
        expect(json_response['data']['attributes']['comment_text']).to eq("This is a test comment")
      end

      it "returns error when content is empty" do
        comment_params = {
          comment: {
            comment_text: ""
          }
        }

        authenticated_request(:post, "/blogs/#{blog.id}/comments", user, comment_params)

        expect_unprocessable_entity_response
        expect_json_response
        expect(json_response['errors']).to be_present
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        comment_params = {
          comment: {
            comment_text: "This is a test comment"
          }
        }

        post "/blogs/#{blog.id}/comments", params: comment_params

        expect_unauthorized_response
      end
    end
  end

  describe "POST /comments/:id/replies" do
    context "when user is authenticated" do
      it "creates a reply to a comment" do
        reply_params = {
          comment: {
            comment_text: "This is a reply"
          }
        }

        authenticated_request(:post, "/comments/#{comment.id}/replies", user, reply_params)

        expect_success_response
        expect_json_response
        expect(json_response['data']['attributes']['comment_text']).to eq("This is a reply")
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        reply_params = {
          comment: {
            comment_text: "This is a reply"
          }
        }

        post "/comments/#{comment.id}/replies", params: reply_params

        expect_unauthorized_response
      end
    end
  end

  describe "POST /comments/:id/upvote" do
    context "when user is authenticated" do
      it "upvotes a comment" do
        authenticated_request(:post, "/comments/#{comment.id}/upvote", user)

        expect_success_response
        expect_json_response
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/comments/#{comment.id}/upvote"

        expect_unauthorized_response
      end
    end
  end

  describe "POST /comments/:id/downvote" do
    context "when user is authenticated" do
      it "downvotes a comment" do
        authenticated_request(:post, "/comments/#{comment.id}/downvote", user)

        expect_success_response
        expect_json_response
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/comments/#{comment.id}/downvote"

        expect_unauthorized_response
      end
    end
  end
end
