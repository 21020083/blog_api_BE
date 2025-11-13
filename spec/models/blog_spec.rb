require 'rails_helper'

RSpec.describe Blog, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    describe '#category_must_be_leaf' do
      context 'when category is nil' do
        it 'allows blog creation' do
          blog = build(:blog, user: user, category: nil)
          expect(blog).to be_valid
        end
      end

      context 'when category is a leaf category (no children)' do
        let(:leaf_category) { create(:category, name: 'Leaf Category') }

        it 'allows blog creation' do
          blog = build(:blog, user: user, category: leaf_category)
          expect(blog).to be_valid
        end
      end

      context 'when category is a parent category (has children)' do
        let(:parent_category) { create(:category, name: 'Parent Category') }
        let!(:child_category) { create(:category, name: 'Child Category', parent_category: parent_category) }

        it 'does not allow blog creation' do
          blog = build(:blog, user: user, category: parent_category)
          expect(blog).not_to be_valid
          expect(blog.errors[:category]).to include('must be a leaf category')
        end
      end

      context 'when category has multiple children' do
        let(:parent_category) { create(:category, name: 'Parent Category') }
        let!(:child1) { create(:category, name: 'Child 1', parent_category: parent_category) }
        let!(:child2) { create(:category, name: 'Child 2', parent_category: parent_category) }

        it 'does not allow blog creation' do
          blog = build(:blog, user: user, category: parent_category)
          expect(blog).not_to be_valid
          expect(blog.errors[:category]).to include('must be a leaf category')
        end
      end

      context 'when category has nested children' do
        let(:grandparent_category) { create(:category, name: 'Grandparent Category') }
        let(:parent_category) { create(:category, name: 'Parent Category', parent_category: grandparent_category) }
        let!(:child_category) { create(:category, name: 'Child Category', parent_category: parent_category) }

        it 'does not allow blog creation with grandparent category' do
          blog = build(:blog, user: user, category: grandparent_category)
          expect(blog).not_to be_valid
          expect(blog.errors[:category]).to include('must be a leaf category')
        end

        it 'does not allow blog creation with parent category' do
          blog = build(:blog, user: user, category: parent_category)
          expect(blog).not_to be_valid
          expect(blog.errors[:category]).to include('must be a leaf category')
        end

        it 'allows blog creation with child category' do
          blog = build(:blog, user: user, category: child_category)
          expect(blog).to be_valid
        end
      end
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      blog = create(:blog, user: user)
      expect(blog.user).to eq(user)
    end

    it 'belongs to category' do
      category = create(:category)
      blog = create(:blog, category: category)
      expect(blog.category).to eq(category)
    end

    it 'has many comments' do
      blog = create(:blog)
      comments = create_list(:comment, 3, blog: blog)
      expect(blog.comments.count).to eq(3)
    end

    it 'has many tags through blog_tags' do
      blog = create(:blog)
      tags = create_list(:tag, 3)
      blog.tags << tags
      expect(blog.tags.count).to eq(3)
    end

    it 'has many bookmarks' do
      blog = create(:blog)
      bookmarks = create_list(:bookmark, 2, blog: blog)
      expect(blog.bookmarks.count).to eq(2)
    end
  end

  describe 'scopes and methods' do
    describe '.top_by_views' do
      let!(:category) { create(:category) }
      let!(:blogs) { create_list(:blog, 5, category: category) }

      before do
        # Create views for blogs
        blogs.each_with_index do |blog, index|
          (index + 1).times do
            create(:blog_view, blog: blog, viewed_at: 1.day.ago)
          end
        end
      end

      it 'returns blogs ordered by views count' do
        range = 2.days.ago..Time.current
        result = Blog.top_by_views(range: range)
        expect(result.first.views_count).to be >= result.last.views_count
      end

      it 'filters by category' do
        other_category = create(:category)
        other_blog = create(:blog, category: other_category)
        create(:blog_view, blog: other_blog, viewed_at: 1.day.ago)

        range = 2.days.ago..Time.current
        result = Blog.top_by_views(range: range, category_id: category.id)
        expect(result.pluck(:category_id).uniq).to eq([ category.id ])
      end
    end

    describe '.top_by_likes' do
      let!(:category) { create(:category) }
      let!(:blogs) { create_list(:blog, 3, category: category) }
      let!(:users) { create_list(:user, 5) }

      before do
        # Create votes for blogs
        blogs.each_with_index do |blog, index|
          (index + 1).times do |i|
            blog.liked_by(users[i])
          end
        end
      end

      it 'returns blogs ordered by likes count' do
        range = 2.days.ago..Time.current
        result = Blog.top_by_likes(range: range)
        expect(result.first.likes_count).to be >= result.last.likes_count
      end
    end

    describe '#log_view' do
      let(:blog) { create(:blog) }
      let(:user) { create(:user) }

      it 'creates a blog view record' do
        expect {
          blog.log_view(user)
        }.to change(BlogView, :count).by(1)
      end

      it 'increments views_count' do
        expect {
          blog.log_view(user)
        }.to change(blog, :views_count).by(1)
      end

      it 'works with anonymous user' do
        expect {
          blog.log_view(nil)
        }.to change(BlogView, :count).by(1)
      end
    end

    describe '#unique_views' do
      let(:blog) { create(:blog) }
      let(:users) { create_list(:user, 3) }

      before do
        users.each do |user|
          create(:blog_view, blog: blog, user: user)
        end
        # Create anonymous view
        create(:blog_view, blog: blog, user: nil)
      end

      it 'returns count of unique users who viewed the blog' do
        expect(blog.unique_views).to eq(3)
      end
    end

    describe '#views_in_range' do
      let(:blog) { create(:blog) }
      let(:start_time) { 2.days.ago }
      let(:end_time) { 1.day.ago }

      before do
        create(:blog_view, blog: blog, viewed_at: 3.days.ago) # Outside range
        create(:blog_view, blog: blog, viewed_at: 1.5.days.ago) # Inside range
        create(:blog_view, blog: blog, viewed_at: 0.5.days.ago) # Outside range
      end

      it 'returns views count within the specified range' do
        expect(blog.views_in_range(start_time, end_time)).to eq(1)
      end
    end

    describe '#summary' do
      let(:blog) { create(:blog, content: "This is a very long content that should be truncated when summary is called. " * 10) }

      it 'returns truncated content' do
        summary = blog.summary(limit: 50)
        expect(summary.length).to be <= 50
        expect(summary).to end_with('...')
      end

      it 'removes HTML tags' do
        blog.update!(content: "<p>This is <strong>HTML</strong> content</p>")
        summary = blog.summary
        expect(summary).not_to include('<p>', '<strong>', '</strong>', '</p>')
      end
    end
  end

  describe 'performance with large datasets' do
    describe 'with 1000 blogs' do
      let!(:blogs) { create_list(:blog, 1000) }
      let!(:category) { create(:category) }
      let!(:category_blogs) { create_list(:blog, 100, category: category) }

      it 'efficiently filters blogs by category' do
        expect {
          Blog.where(category: category).count
        }.to complete_within(1.second)
      end

      it 'efficiently paginates blogs' do
        expect {
          Blog.page(1).per(20).to_a
        }.to complete_within(1.second)
      end

      it 'efficiently loads blogs with associations' do
        expect {
          Blog.includes(:user, :category, :tags).limit(50).to_a
        }.to complete_within(1.second)
      end
    end

    describe 'with 10000 blog views' do
      let!(:blog) { create(:blog) }
      let!(:users) { create_list(:user, 100) }

      before do
        # Create 10000 views
        100.times do
          users.each do |user|
            create(:blog_view, blog: blog, user: user, viewed_at: rand(30.days).seconds.ago)
          end
        end
      end

      it 'efficiently counts unique views' do
        expect {
          blog.unique_views
        }.to complete_within(2.seconds)
      end

      it 'efficiently counts views in range' do
        start_time = 1.week.ago
        end_time = Time.current
        expect {
          blog.views_in_range(start_time, end_time)
        }.to complete_within(2.seconds)
      end
    end
  end
end
