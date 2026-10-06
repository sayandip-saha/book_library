class BooksController < ApplicationController
  def index
  @books = Book.all

  if params[:query].present?
    @books = @books.where("title LIKE ?", "%#{params[:query]}%")
  end

  if params[:author_id].present?
    @books = @books.where(author_id: params[:author_id])
  end

  if params[:category_id].present?
    @books = @books.where(category_id: params[:category_id])
  end

  @books = @books.order(title: :asc)

  @authors = Author.order(:name)
  @categories = Category.order(:name)

  @book_count = Book.count
  @author_count = Author.count
  @category_count = Category.count
end

  def show
    @book = Book.find(params[:id])
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @book = Book.find(params[:id])
  end

  def update
    @book = Book.find(params[:id])

    if @book.update(book_params)
      redirect_to @book
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book = Book.find(params[:id])
    @book.destroy

    redirect_to books_path
  end

  private

  def book_params
    params.expect(
      book: [
        :title,
        :isbn,
        :publication_year,
        :description,
        :available,
        :author_id,
        :category_id
      ]
    )
  end
end