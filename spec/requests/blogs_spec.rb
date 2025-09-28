require 'rails_helper'

RSpec.describe "Blogs API", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:blog) { create(:blog, user: user, category: category) }

  describe "GET /blogs" do
    it "returns all blogs" do
      blog # Create the blog
      get "/blogs"

      expect_success_response
      expect_json_response
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(1)
    end

    it "returns paginated blogs" do
      create_list(:blog, 15, user: user, category: category)
      get "/blogs", params: { page: 1, per_page: 10 }

      expect_success_response
      expect_json_response
      expect(json_response['data'].length).to eq(10)
    end
  end

  describe "GET /blogs/:id" do
    it "returns a specific blog" do
      get "/blogs/#{blog.id}"

      expect_success_response
      expect_json_response
      expect(json_response['data']['id']).to eq(blog.id.to_s)
      expect(json_response['data']['attributes']['title']).to eq(blog.title)
    end

    it "returns not found for non-existent blog" do
      get "/blogs/99999"

      expect_not_found_response
    end
  end

  describe "POST /blogs" do
    context "when user is authenticated" do
      it "creates a new blog" do
        blog_params = {
          blog: {
            title: "Test Blog Title",
            content: "This is test blog content",
            category_id: category.id
          }
        }

        authenticated_request(:post, "/blogs", user, blog_params)

        expect_success_response
        expect_json_response
        expect(json_response['data']['attributes']['title']).to eq("Test Blog Title")
        expect(json_response['data']['attributes']['content']).to eq("This is test blog content")
      end

      it "returns error when title is empty" do
        blog_params = {
          blog: {
            title: "",
            content: "This is test blog content",
            category_id: category.id
          }
        }

        authenticated_request(:post, "/blogs", user, blog_params)

        expect_unprocessable_entity_response
        expect_json_response
        expect(json_response['errors']).to be_present
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        blog_params = {
          blog: {
            title: "Test Blog Title",
            content: "This is test blog content",
            category_id: category.id
          }
        }

        post "/blogs", params: blog_params

        expect_unauthorized_response
      end
    end
  end

  describe "POST /blogs/:id/upvote" do
    context "when user is authenticated" do
      it "upvotes a blog" do
        authenticated_request(:post, "/blogs/#{blog.id}/upvote", user)

        expect_success_response
        expect_json_response
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/blogs/#{blog.id}/upvote"

        expect_unauthorized_response
      end
    end
  end

  describe "POST /blogs/:id/downvote" do
    context "when user is authenticated" do
      it "downvotes a blog" do
        authenticated_request(:post, "/blogs/#{blog.id}/downvote", user)

        expect_success_response
        expect_json_response
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/blogs/#{blog.id}/downvote"

        expect_unauthorized_response
      end
    end
  end

  describe "GET /blogs/:id/comments" do
    it "returns comments for a blog" do
      create_list(:comment, 3, blog: blog, user: user)
      get "/blogs/#{blog.id}/comments"

      expect_success_response
      expect_json_response
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(3)
    end
  end
end
