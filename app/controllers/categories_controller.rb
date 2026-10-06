class CategoriesController < ApplicationController
  def index
    @categories = Category.all.order(:name)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to categories_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
  @category = Category.find(params[:id])

  if @category.destroy
    redirect_to categories_path, notice: "Category deleted successfully."
  else
    redirect_to categories_path,
                alert: @category.errors.full_messages.to_sentence
  end
end

  private

  def category_params
    params.expect(category: [:name])
  end
end