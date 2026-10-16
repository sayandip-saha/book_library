class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[ index show lookup ]

  def index
    @books = Book.includes(:author, :category)

    if params[:query].present?
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(params[:query])
      @books = @books.where("title LIKE ?", "%#{sanitized_query}%")
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
    @book = Book.new(available: true)
  end

  def lookup
    isbn = params[:isbn].to_s.strip
    create_book = params[:create_book] == "true"
    result = OpenLibraryService.fetch_by_isbn(isbn, create_associations: true, create_book: create_book)
    render json: result
  end

  def import
    isbn = params[:isbn].to_s.strip
    result = OpenLibraryService.fetch_by_isbn(isbn, create_associations: true, create_book: true)

    if result[:success] && result[:book_id].present?
      redirect_to book_path(result[:book_id]), notice: "✨ \"#{result[:title]}\" by #{result[:author_name]} was successfully imported and saved to the library!"
    else
      error_msg = result[:error] || "Could not fetch book details from Open Library."
      redirect_to new_book_path, alert: error_msg
    end
  end

  def toggle_availability
    @book = Book.find(params[:id])
    @book.update(available: !@book.available)
    status_label = @book.available? ? "Available in Library" : "Marked as Borrowed"
    redirect_to @book, notice: "\"#{@book.title}\" is now #{status_label}."
  end

  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book, notice: "Book was successfully created."
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
      redirect_to @book, notice: "Book was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book = Book.find(params[:id])
    @book.destroy

    redirect_to books_path, notice: "Book was successfully deleted."
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
        :category_id,
        :cover_image_url
      ]
    )
  end
end