class CategoriesController < ApplicationController
  include Authorizable
  before_action :authenticate_user!, :authorize_admin!, only: [ :create, :update, :destroy ]
  before_action :set_category, only: [ :show, :update, :destroy ]

  def index
    root_categories = Category.root_categories.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(root_categories)
    render_success(resource: root_categories, meta: meta)
  end

  def show
    render_success(resource: @category)
  end

  def create
    category = Category.new(category_params)
    category.current_audit_user = current_user
    if category.save
      render_success(resource: category, status: :created)
    else
      render_error(errors: category.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def update
    if @category.update(category_params)
      render_success(resource: @category)
    else
      render_error(errors: @category.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def destroy
    if @category.destroy
      render_success(status: :no_content)
    else
      render_error(errors: @category.errors.full_messages, status: :unprocessable_entity)
    end
  end

  private

  def set_category
    @category = Category.friendly.find_by(id: params[:id])
    render_error errors: "Category not found", status: :not_found unless @category
  end

  def category_params
    params.require(:category).permit(:name, :parent_category_id)
  end
end
