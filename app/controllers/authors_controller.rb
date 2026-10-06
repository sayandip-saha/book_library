class AuthorsController < ApplicationController
  def index
    @authors = Author.all.order(:name)
  end

  def new
    @author = Author.new
  end

  def create
    @author = Author.new(author_params)

    if @author.save
      redirect_to authors_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
  @author = Author.find(params[:id])

  if @author.destroy
    redirect_to authors_path, notice: "Author deleted successfully."
  else
    redirect_to authors_path,
                alert: @author.errors.full_messages.to_sentence
  end
end

  private

  def author_params
    params.expect(author: [:name])
  end
end