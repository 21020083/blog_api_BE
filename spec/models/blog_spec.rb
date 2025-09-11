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
end
