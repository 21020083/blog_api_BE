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

    it "filters blogs by category" do
      other_category = create(:category)
      create_list(:blog, 5, user: user, category: category)
      create_list(:blog, 3, user: user, category: other_category)

      get "/blogs", params: { category_id: category.id }

      expect_success_response
      expect_json_response
      expect(json_response['data'].length).to eq(5)
    end

    it "filters blogs by user" do
      other_user = create(:user)
      create_list(:blog, 5, user: user, category: category)
      create_list(:blog, 3, user: other_user, category: category)

      get "/blogs", params: { user_id: user.id }

      expect_success_response
      expect_json_response
      expect(json_response['data'].length).to eq(5)
    end

    it "filters blogs by tags" do
      tag1 = create(:tag)
      tag2 = create(:tag)
      blog1 = create(:blog, user: user, category: category)
      blog2 = create(:blog, user: user, category: category)
      blog1.tags << tag1
      blog2.tags << tag2

      get "/blogs", params: { tag_ids: [ tag1.id ] }

      expect_success_response
      expect_json_response
      expect(json_response['data'].length).to eq(1)
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

    it "logs view when blog is accessed" do
      expect {
        get "/blogs/#{blog.id}"
      }.to change(BlogView, :count).by(1)
    end

    it "does not log duplicate views for same user" do
      authenticated_request(:get, "/blogs/#{blog.id}", user)
      expect {
        authenticated_request(:get, "/blogs/#{blog.id}", user)
      }.not_to change(BlogView, :count)
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

      it "creates a blog with tags" do
        tag1 = create(:tag)
        tag2 = create(:tag)
        blog_params = {
          blog: {
            title: "Test Blog Title",
            content: "This is test blog content",
            category_id: category.id,
            tag_ids: [ tag1.id, tag2.id ]
          }
        }

        authenticated_request(:post, "/blogs", user, blog_params)

        expect_success_response
        created_blog = Blog.find(json_response['data']['id'])
        expect(created_blog.tags.count).to eq(2)
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

  describe "PUT /blogs/:id" do
    context "when user is authenticated" do
      it "updates a blog" do
        blog_params = {
          blog: {
            title: "Updated Blog Title",
            content: "Updated content"
          }
        }

        authenticated_request(:put, "/blogs/#{blog.id}", user, blog_params)

        expect_success_response
        expect_json_response
        expect(json_response['data']['attributes']['title']).to eq("Updated Blog Title")
      end

      it "returns error when trying to update other user's blog" do
        other_user = create(:user)
        blog_params = {
          blog: {
            title: "Updated Blog Title"
          }
        }

        authenticated_request(:put, "/blogs/#{blog.id}", other_user, blog_params)

        expect_forbidden_response
      end
    end
  end

  describe "DELETE /blogs/:id" do
    context "when user is authenticated" do
      it "deletes a blog" do
        authenticated_request(:delete, "/blogs/#{blog.id}", user)

        expect_success_response
        expect(Blog.find_by(id: blog.id)).to be_nil
      end

      it "returns error when trying to delete other user's blog" do
        other_user = create(:user)

        authenticated_request(:delete, "/blogs/#{blog.id}", other_user)

        expect_forbidden_response
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

  describe "Performance tests with large datasets" do
    describe "GET /blogs with 1000 blogs" do
      before do
        create_list(:blog, 1000, :with_tags, :with_comments, :with_views)
      end

      it "efficiently returns paginated blogs" do
        expect {
          get "/blogs", params: { page: 1, per_page: 20 }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to eq(20)
      end

      it "efficiently filters blogs by category" do
        category = create(:category)
        create_list(:blog, 100, category: category)

        expect {
          get "/blogs", params: { category_id: category.id }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to eq(100)
      end

      it "efficiently filters blogs by tags" do
        tag = create(:tag)
        blogs = create_list(:blog, 50)
        blogs.each { |blog| blog.tags << tag }

        expect {
          get "/blogs", params: { tag_ids: [ tag.id ] }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to eq(50)
      end
    end

    describe "GET /blogs/:id with many views" do
      let(:blog) { create(:blog, :with_views, views_count: 1000) }

      it "efficiently returns blog details" do
        expect {
          get "/blogs/#{blog.id}"
        }.to complete_within(1.second)

        expect_success_response
        expect(json_response['data']['attributes']['views_count']).to eq(1000)
      end
    end
  end
end
