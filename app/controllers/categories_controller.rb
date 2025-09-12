class CategoriesController < ApplicationController
  before_action :authenticate_user!, :is_admin?, only: [ :create, :update, :destroy ]
  before_action :set_category, only: [ :show, :update, :destroy ]

  def index
    root_categories = Category.root_categories.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(root_categories)
    render_success(resource: root_categories, meta: meta)
  end

  def show
    blogs = @category.blogs_from_leaf_descendants
    render_success(resource: { category: @category, blogs: blogs })
  end

  def create
    category = Category.new(category_params)
    if category.save
      render_success(resource: category, status: :created)
    else
      render_error(errors: category.errors.full_messages)
    end
  end

  def update
    if @category.update(category_params)
      render_success(resource: @category)
    else
      render_error(errors: @category.errors.full_messages)
    end
  end

  def destroy
    @category.destroy
    render_success(message: "Category deleted")
  end

  private

  def set_category
    @category = Category.friendly.find(params[:id])
    render_error errors: "Category not found", status: :not_found unless @category
  end

  def category_params
    params.require(:category).permit(:name, :parent_category_id)
  end

  def is_admin?
    render_error(errors: "Unauthorized", status: :unauthorized) unless current_user&.admin?
  end
end
