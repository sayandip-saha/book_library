# Book Library — Technical Implementation Guide (`implementation.md`)

## 1. Technical Stack & Dependencies

The application is engineered on the modern **Ruby on Rails 8** framework, leveraging Rails 8 defaults for zero-dependency frontend pipelines, SQLite-backed services, and production acceleration.

| Component | Technology | Version / Specification |
| :--- | :--- | :--- |
| **Language** | Ruby | `3.4.10` (defined in `.ruby-version`) |
| **Web Framework** | Ruby on Rails | `~> 8.1.3` (Rails 8.1) |
| **Database** | SQLite3 | `>= 2.1` with WAL mode support |
| **App Server** | Puma | `>= 5.0` |
| **Web Accelerator** | Thruster | HTTP caching, gzip/brotli compression, X-Sendfile |
| **Asset Pipeline** | Propshaft | Modern asset packaging (no Webpack/Node build step required) |
| **JavaScript Delivery** | Importmap-rails | Native ES modules delivered via browser import maps |
| **Frontend Frameworks**| Turbo & Stimulus | Hotwire standard suite (`turbo-rails`, `stimulus-rails`) |
| **Background & Queue** | Solid Queue | DB-backed background processing (`solid_queue`) |
| **Cache Store** | Solid Cache | DB-backed key-value caching (`solid_cache`) |
| **Action Cable** | Solid Cable | DB-backed real-time websockets (`solid_cable`) |
| **Deployment Engine** | Kamal & Docker | Multi-stage slim Docker image with non-root runtime |

---

## 2. Database Architecture & Schema

### 2.1 Entity Relationship Diagram (ERD)

```
       +-----------------------+
       |        authors        |
       +-----------------------+
       | id: integer (PK)      |
       | name: string          |
       | created_at: datetime  |
       | updated_at: datetime  |
       +-----------+-----------+
                   | 1
                   |
                   | has_many
                   | restricts deletion
                   v *
       +-------------------------------+       * +-----------------------+
       |             books             | <-------+      categories       |
       +-------------------------------+ 1       +-----------------------+
       | id: integer (PK)              |         | id: integer (PK)      |
       | title: string                 |         | name: string          |
       | isbn: string (unique)         |         | created_at: datetime  |
       | publication_year: integer     |         | updated_at: datetime  |
       | description: text             |         +-----------------------+
       | available: boolean            |
       | author_id: integer (FK)       |
       | category_id: integer (FK)     |
       | created_at: datetime          |
       | updated_at: datetime          |
       +-------------------------------+
```

### 2.2 Table Definitions (`db/schema.rb`)

#### Table: `authors`
- `id` (INTEGER, Primary Key, Auto-increment)
- `name` (STRING)
- `created_at` (DATETIME, NOT NULL)
- `updated_at` (DATETIME, NOT NULL)

#### Table: `categories`
- `id` (INTEGER, Primary Key, Auto-increment)
- `name` (STRING)
- `created_at` (DATETIME, NOT NULL)
- `updated_at` (DATETIME, NOT NULL)

#### Table: `books`
- `id` (INTEGER, Primary Key, Auto-increment)
- `title` (STRING)
- `isbn` (STRING)
- `publication_year` (INTEGER)
- `description` (TEXT)
- `available` (BOOLEAN)
- `author_id` (INTEGER, Foreign Key referencing `authors.id`)
- `category_id` (INTEGER, Foreign Key referencing `categories.id`)
- `created_at` (DATETIME, NOT NULL)
- `updated_at` (DATETIME, NOT NULL)
- **Indices:**
  - `index_books_on_author_id` on `author_id`
  - `index_books_on_category_id` on `category_id`
- **Foreign Keys:**
  - `add_foreign_key "books", "authors"`
  - `add_foreign_key "books", "categories"`

### 2.3 Migration History

1. `20261006054941_create_books.rb` — Initial books table creation (title, isbn, publication_year, description, available).
2. `20261006055100_create_authors.rb` — Authors table creation (name).
3. `20261006055128_create_categories.rb` — Categories table creation (name).
4. `20261006055251_add_author_and_category_to_books.rb` — Adds `author_id` and `category_id` foreign key references and indices to `books`.

---

## 3. Model Layer Implementation

### 3.1 `Book` (`app/models/book.rb`)
```ruby
class Book < ApplicationRecord
  belongs_to :author
  belongs_to :category

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :publication_year, presence: true
end
```
- **Associations:** Requires valid foreign keys for both `Author` and `Category`.
- **Validations:** Ensures `title`, `isbn`, and `publication_year` are never blank; enforces that ISBN values are globally distinct.

### 3.2 `Author` (`app/models/author.rb`)
```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :restrict_with_error

  validates :name, presence: true
end
```
- **Safety Mechanism:** `dependent: :restrict_with_error` prevents accidental cascade deletion of authors who have books currently in the library.

### 3.3 `Category` (`app/models/category.rb`)
```ruby
class Category < ApplicationRecord
  has_many :books, dependent: :restrict_with_error

  validates :name, presence: true
end
```
- **Safety Mechanism:** Same deletion restriction preserves catalog integrity when categories have associated books.

---

## 4. Controller & Routing Implementation

### 4.1 Route Declarations (`config/routes.rb`)
```ruby
Rails.application.routes.draw do
  resources :books
  resources :authors, only: [:index, :new, :create, :destroy]
  resources :categories, only: [:index, :new, :create, :destroy]

  root "books#index"
end
```

### 4.2 `BooksController` (`app/controllers/books_controller.rb`)
- **Index & Multi-Parameter Filter Action:**
  ```ruby
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
  ```
  - Employs parameterized SQL queries (`?`) to prevent SQL injection vulnerabilities.
  - Returns counts for collection-level summary stat widgets.
- **Rails 8 Strong Parameters:**
  ```ruby
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
  ```
  - Uses the Rails 8 `params.expect` syntax for strong typing and explicit parameter filtering.

### 4.3 `AuthorsController` & `CategoriesController`
- Handles collection index, creation, and secure deletion.
- Returns user-friendly alerts when an author or category cannot be deleted due to associated books:
  ```ruby
  def destroy
    @author = Author.find(params[:id])
    if @author.destroy
      redirect_to authors_path, notice: "Author deleted successfully."
    else
      redirect_to authors_path, alert: @author.errors.full_messages.to_sentence
    end
  end
  ```

---

## 5. Frontend & UI Architecture

### 5.1 Design System & CSS Token Architecture
The styling is implemented in `app/assets/stylesheets/application.css` without external CSS preprocessors, using pure CSS3 custom properties:

```css
:root {
  --bg: #080b14;
  --bg-soft: #0f1322;
  --card: rgba(20, 25, 42, 0.78);
  --card-hover: rgba(28, 34, 56, 0.9);
  --border: rgba(255, 255, 255, 0.09);
  --text: #f4f7ff;
  --text-muted: #98a2bd;
  --primary: #8b5cf6;
  --primary-light: #a78bfa;
  --cyan: #22d3ee;
  --success: #34d399;
  --danger: #fb7185;
  --shadow: 0 20px 60px rgba(0, 0, 0, 0.35);
  --radius: 20px;
}
```

### 5.2 UI Components
1. **Sticky Glassmorphism Navbar:** Backdrop filter blur (`backdrop-filter: blur(18px)`) with glowing brand badge and navigation links.
2. **Dashboard Stats Grid:** Responsive 3-column metric cards showing real-time counts for Books, Authors, and Categories.
3. **Filter & Search Panel:** Multi-input filter row for real-time text query and dropdown filters with "Search" and "Clear Filters" actions.
4. **Book Card Grid:** Glassmorphic card design with hover elevation (`transform: translateY(-8px)`), radial lighting accents, status badges, and action shortcuts.
5. **Form Architecture:** Dark-themed inputs with focus halos (`box-shadow: 0 0 0 4px rgba(139, 92, 246, 0.1)`), formatted validation error boxes, and cancel fallbacks.
6. **Detailed Show View:** Split info grid showing ISBN, Author, Category, Publication Year, Availability status, and full synopsis.

---

## 6. Security & Data Integrity

1. **SQL Injection Prevention:** All dynamic queries use parameterized active record queries (`@books.where("title LIKE ?", "%#{query}%")`).
2. **Cross-Site Request Forgery (CSRF):** Standard Rails authenticity token protection via `<%= csrf_meta_tags %>` and Rails form helpers (`form_with`, `button_to`).
3. **Content Security Policy (CSP):** Initializer configured in `config/initializers/content_security_policy.rb`.
4. **Foreign Key Integrity:** Database-level foreign keys (`add_foreign_key`) combined with Rails `dependent: :restrict_with_error`.
5. **Strong Parameter Whitelisting:** Using Rails 8 `params.expect` prevents mass assignment vulnerabilities.

---

## 7. Containerization & Production Deployment

### 7.1 Docker Multi-Stage Architecture (`Dockerfile`)
- **Base Layer:** `docker.io/library/ruby:3.4.10-slim`, installs `jemalloc2`, `sqlite3`, and `libvips`.
- **Build Layer:** Installs compilation packages (`build-essential`, `pkg-config`), runs `bundle install`, precompiles `bootsnap` cache, and executes `./bin/rails assets:precompile`.
- **Runtime Layer:** Creates non-root system user `rails:rails` (UID 1000) for security hardening.
- **Web Acceleration:** Starts via Thruster (`./bin/thrust ./bin/rails server`) on port 80.

### 7.2 Entrypoint Workflow (`bin/docker-entrypoint`)
Prepares database on initial startup:
```bash
if [ "${1}" = "./bin/rails" ] || [ "${1}" = "./bin/thrust" ]; then
  ./bin/rails db:prepare
fi
```
Ensures SQLite migrations are automatically applied on container startup.
