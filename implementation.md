# Book Library — Technical Implementation Guide (`implementation.md`)

## 1. Technical Stack & Dependencies

The application is engineered on **Ruby on Rails 8**, leveraging modern defaults for zero-dependency frontend pipelines, MySQL database storage, and production container acceleration.

| Component | Technology | Version / Specification |
| :--- | :--- | :--- |
| **Language** | Ruby | `3.4.10` (defined in `.ruby-version`) |
| **Web Framework** | Ruby on Rails | `~> 8.1.3` (Rails 8.1) |
| **Database** | MySQL | `>= 8.0` via `trilogy` adapter with UTF8MB4 |
| **Authentication** | Rails 8 Built-in Auth | `has_secure_password` via `bcrypt (~> 3.1.7)` |
| **Session Tracking** | Active Record & Signed Cookies | Database-backed sessions via `Current.session` |
| **Rate Limiter** | Rails 8 Controller Rate Limiting | IP-based request throttling on auth endpoints |
| **App Server** | Puma | `>= 5.0` |
| **Web Accelerator** | Thruster | HTTP caching, gzip/brotli compression, X-Sendfile |
| **Asset Pipeline** | Propshaft | Zero-build modern asset delivery (`application.css` & `app.css`) |
| **JavaScript Delivery** | Importmap-rails | Native browser ES modules (no Node/Webpack required) |
| **Typography** | Google Fonts | `Plus Jakarta Sans` (body) & `Outfit` (headings) |
| **Frontend Utilities** | Turbo & Stimulus | Hotwire standard suite (`turbo-rails`, `stimulus-rails`) |
| **Background & Queue** | Solid Queue | Database-backed asynchronous queue (`solid_queue`) |
| **Cache Store** | Solid Cache | Database-backed key-value caching (`solid_cache`) |
| **Action Cable** | Solid Cable | Database-backed real-time websockets (`solid_cable`) |
| **Deployment Engine** | Kamal & Docker | Multi-stage slim Docker image with non-root runtime |

---

## 2. Database Architecture & Schema

### 2.1 Entity Relationship Diagram (ERD)

```
       +-----------------------+                   +-----------------------+
       |        authors        |                   |         users         |
       +-----------------------+                   +-----------------------+
       | id: integer (PK)      |                   | id: integer (PK)      |
       | name: string          |                   | email_address: string |
       | created_at: datetime  |                   | password_digest: str  |
       | updated_at: datetime  |                   | created_at: datetime  |
       +-----------+-----------+                   | updated_at: datetime  |
                   | 1                             +-----------+-----------+
                   |                                           | 1
                   | has_many                                  | has_many
                   | restricts deletion                        | destroys
                   v *                                         v *
       +-------------------------------+           +-----------------------+
       |             books             |           |       sessions        |
       +-------------------------------+           +-----------------------+
       | id: integer (PK)              |           | id: integer (PK)      |
       | title: string                 |           | user_id: integer (FK) |
       | isbn: string (unique)         |           | ip_address: string    |
       | publication_year: integer     |           | user_agent: string    |
       | description: text             |           | created_at: datetime  |
       | available: boolean            |           | updated_at: datetime  |
       | author_id: integer (FK)       |           +-----------------------+
       | category_id: integer (FK)     |
       | created_at: datetime          |
       | updated_at: datetime          |
       +---------------+---------------+
                       ^ *
                       | 1 has_many (restricts deletion)
       +---------------+---------------+
       |          categories           |
       +-------------------------------+
       | id: integer (PK)              |
       | name: string                  |
       | created_at: datetime          |
       | updated_at: datetime          |
       +-------------------------------+
```

### 2.2 Table Definitions (`db/schema.rb`)

#### Table: `users`
- `id` (BIGINT, Primary Key, Auto-increment)
- `email_address` (STRING/VARCHAR(255), NOT NULL, UNIQUE index)
- `password_digest` (STRING/VARCHAR(255), NOT NULL)
- `created_at`, `updated_at` (DATETIME(6), NOT NULL)

#### Table: `sessions`
- `id` (BIGINT, Primary Key, Auto-increment)
- `user_id` (BIGINT, NOT NULL, Foreign Key referencing `users.id`)
- `ip_address` (STRING)
- `user_agent` (STRING)
- `created_at`, `updated_at` (DATETIME(6), NOT NULL)

#### Table: `books`
- `id` (BIGINT, Primary Key, Auto-increment)
- `title` (STRING/VARCHAR(255))
- `isbn` (STRING/VARCHAR(255), UNIQUE)
- `publication_year` (INTEGER/INT)
- `description` (TEXT)
- `available` (BOOLEAN/TINYINT(1))
- `cover_image_url` (STRING/VARCHAR(255))
- `author_id` (BIGINT, Foreign Key referencing `authors.id`)
- `category_id` (BIGINT, Foreign Key referencing `categories.id`)
- `created_at`, `updated_at` (DATETIME(6), NOT NULL)

#### Table: `authors` & `categories`
- `id` (BIGINT, Primary Key, Auto-increment)
- `name` (STRING/VARCHAR(255))
- `created_at`, `updated_at` (DATETIME(6), NOT NULL)

### 2.3 Migration History
1. `20261006054941_create_books.rb` — Base books table.
2. `20261006055100_create_authors.rb` — Base authors table.
3. `20261006055128_create_categories.rb` — Base categories table.
4. `20261006055251_add_author_and_category_to_books.rb` — Foreign keys and indices for authors/categories on books.
5. `20261012042108_create_users.rb` — Users table with unique email index.
6. `20261012042109_create_sessions.rb` — Sessions table linked to users.
7. `20261016102000_add_cover_image_url_to_books.rb` — Add `cover_image_url` string column to `books`.

---

## 3. Model Layer Implementation

### 3.1 `User` (`app/models/user.rb`)
```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end
end
```
- **Password Security:** Salted and hashed using BCrypt.
- **Email Normalization & Validation:** Strips whitespace, converts to lowercase, and validates RFC 5322 email syntax.
- **Token Generation:** Produces time-limited (15 minutes) signed tokens tied to the password salt.

### 3.2 `Session` & `Current` (`app/models/session.rb`, `app/models/current.rb`)
```ruby
class Session < ApplicationRecord
  belongs_to :user
end

class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```
- Provides thread-safe, request-isolated access to `Current.session` and `Current.user`.

### 3.3 `Book` (`app/models/book.rb`)
```ruby
class Book < ApplicationRecord
  belongs_to :author
  belongs_to :category

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :publication_year, presence: true

  def cover_url
    cover_image_url.presence || default_open_library_cover
  end

  def default_open_library_cover
    return nil if isbn.blank?
    clean_isbn = isbn.gsub(/[^0-9X]/i, "")
    "https://covers.openlibrary.org/b/isbn/#{clean_isbn}-M.jpg?default=false"
  end
end
```
- **Cover Resolution:** `cover_url` prioritizes explicit `cover_image_url` fetched from Open Library API and gracefully falls back to direct Open Library ISBN cover endpoints.

### 3.4 `OpenLibraryService` (`app/services/open_library_service.rb`)
```ruby
class OpenLibraryService
  BASE_URL = "https://openlibrary.org/api/books"

  CANONICAL_GENRES = {
    "Dystopian" => ["dystop", "totalitarian", "authoritarian", "1984", "orwellian"],
    "Fantasy" => ["magic", "wizard", "witches", "dragon", "mythology", "sorcery", "hogwarts", "fantasy"],
    "Science Fiction" => ["space opera", "time travel", "cyberpunk", "extraterrestrial", "science fiction", "scifi"],
    "Mystery & Thriller" => ["thriller", "suspense", "mystery", "detective", "crime", "espionage"],
    "Classics" => ["classic literature", "fiction classics", "classics"],
    "Historical Fiction" => ["historical fiction", "regency", "victorian", "world war", "civil war", "gothic"],
    "Romance" => ["romance", "courtship", "love stories"],
    "Computer Science & Tech" => ["computer", "software", "programming", "coding", "agile", "web development"],
    # ... additional canonical genres (Philosophy, History, Biography, Politics, etc.)
  }.freeze

  def self.fetch_by_isbn(isbn, create_associations: true, create_book: false)
    # Fetches from Open Library API, extracts author and canonical category,
    # finds or creates Author and Category in database, and optionally creates Book
  end
end
```
- **Real Author & Category Extraction:** Intelligently matches book subjects against canonical literary genres with specificity weighting, and resolves Open Library `/authors/OL...` keys when required.
- **Database Persistence During Auto-Fetch:** During ISBN auto-fetch, automatically creates or finds `Author` and `Category` records in the database, returning valid foreign keys (`author_id`, `category_id`) to the form.
- **Optional Direct Book Import:** Supports `create_book: true` to persist the book directly to the database in a single step.

### 3.5 `Author` & `Category` (`app/models/author.rb`, `app/models/category.rb`)
```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :restrict_with_error
  validates :name, presence: true
end

class Category < ApplicationRecord
  has_many :books, dependent: :restrict_with_error
  validates :name, presence: true
end
```
- **Integrity Safeguard:** `dependent: :restrict_with_error` prevents accidental cascading deletes when books remain associated.

---

## 4. Controller & Routing Implementation

### 4.1 Route Declarations (`config/routes.rb`)
```ruby
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :books do
    collection do
      get :lookup
      post :import
    end
    member do
      patch :toggle_availability
    end
  end
  resources :authors, only: [:index, :new, :create, :destroy]
  resources :categories, only: [:index, :new, :create, :destroy]
  resources :users, only: %i[new create]

  root "books#index"
end
```

### 4.2 `Authentication` Concern (`app/controllers/concerns/authentication.rb`)
- Included in `ApplicationController`.
- Enforces `before_action :require_authentication` globally.
- Provides `allow_unauthenticated_access(**options)` for public actions.
- Automatically stores `session[:return_to_after_authenticating]` to return users to their intended page upon login.

### 4.3 Controller Permissions & Optimization
- **`BooksController`:**
  - Publicly accessible: `allow_unauthenticated_access only: %i[ index show lookup ]`.
  - Mutating actions (`new`, `create`, `edit`, `update`, `destroy`, `import`, `toggle_availability`) require authentication.
  - **Open Library Lookup:** `lookup` endpoint accepts `params[:isbn]`, queries Open Library, automatically persists the Author and Category into the database, and returns JSON metadata.
  - **Direct Book Import:** `import` endpoint (`POST /books/import`) fetches and saves the Author, Category, and Book directly to the database and redirects to the book's show page.
  - **Instant Availability Flip:** `toggle_availability` toggles `book.available` status in one click and redirects back with confirmation notice.
  - **Permitted Parameters:** Permits `:title`, `:isbn`, `:publication_year`, `:description`, `:available`, `:cover_image_url`, `:author_id`, `:category_id`.
  - **N+1 Optimization:** Uses `@books = Book.includes(:author, :category)`.
  - **Sanitized Search:** Uses `ActiveRecord::Base.sanitize_sql_like(params[:query])` to prevent SQL wildcard attacks.
- **`AuthorsController` & `CategoriesController`:**
  - Public index: `allow_unauthenticated_access only: %i[ index ]`.
  - Eager loads books count: `includes(:books)` to eliminate loop query overhead.
- **`SessionsController`:**
  - Rate-limited: `rate_limit to: 10, within: 3.minutes, only: :create`.
  - Issues signed permanent cookies: `cookies.signed.permanent[:session_id]`.
- **`PasswordsController` & `PasswordsMailer`:**
  - Handles token-based password reset with expiring links and Action Mailer delivery.

---

## 5. Frontend & UI Architecture

### 5.1 Design System Tokens & Typography
Implemented in `app/assets/stylesheets/application.css` (with `app.css` wrapper for Propshaft):

```css
:root {
  --bg: #070a13;
  --bg-surface: #0e1322;
  --card: rgba(18, 24, 40, 0.75);
  --card-hover: rgba(26, 33, 56, 0.9);
  --border: rgba(255, 255, 255, 0.08);
  --border-focus: rgba(139, 92, 246, 0.55);

  --text: #f8fafc;
  --text-muted: #94a3b8;
  --text-dim: #64748b;

  --primary: #8b5cf6;
  --primary-glow: rgba(139, 92, 246, 0.28);
  --cyan: #06b6d4;
  --emerald: #10b981;
  --rose: #f43f5e;
  --amber: #f59e0b;
}
```

### 5.2 UI Components
1. **Glassmorphism Navbar:** Sticky header with backdrop blur (`blur(20px)`), brand icon badge (`📚`), active page tab indicator, and user profile pill (`.user-pill`) showing the logged-in email.
2. **Hero Header & Pulse Badge:** Clean collection showcase with a live pulsating dot (`● Personal Library Catalog`) and gradient typography.
3. **Color-Coded Metrics:** 3-column stats cards with dedicated glow accents (Books = Violet, Authors = Cyan, Categories = Amber).
4. **Command-Center Search Panel:** Integrated title search with input icon, custom dropdown selectors, live result counter, and active filter clear shortcut.
5. **3D Book Cards:** Book cards featuring category genre pill, glowing circulation status indicator (`● Available` / `● Borrowed`), 3D cover spine mockup, author monogram avatar, synopsis snippet, and action shortcuts.
6. **2-Column Detailed Showcase (`show.html.erb`):** Left presentation column with 3D cover card, year emblem, and ISBN barcode; right column with author strip, specification grid, and reading synopsis box.
7. **Custom Toggle Card:** Clean slide-toggle for availability status instead of standard checkboxes.
8. **Global Flash Notifications:** Glassmorphic notification banners (`.alert-success` with green accent, `.alert-danger` with rose accent).

---

## 6. Security & Data Integrity

1. **Password Hashing:** Industry-standard BCrypt cost-factor hashing via `has_secure_password`.
2. **Session Security:** Cryptographically signed, HTTP-only, `same_site: :lax` session cookies.
3. **Rate Limiting:** Protects `/session` and `/passwords` from credential stuffing and brute-force attacks.
4. **SQL Injection Prevention:** Parameterized SQL queries and `sanitize_sql_like` parameter cleaning.
5. **Cross-Site Request Forgery (CSRF):** Standard Rails authenticity tokens validated across all non-GET requests.
6. **Content Security Policy (CSP):** Enforced via `config/initializers/content_security_policy.rb`.
7. **Foreign Key Integrity:** Database constraints (`add_foreign_key`) paired with Active Record deletion locks (`dependent: :restrict_with_error`).

---

## 7. Containerization & Production Deployment

### 7.1 Dockerfile Specification
- **Base:** `docker.io/library/ruby:3.4.10-slim` with `jemalloc2`, `sqlite3`, and `libvips`.
- **Multi-Stage Build:** Dependencies compiled in build stage, copied to slim runtime image.
- **Bootsnap Cache:** Precompiled bootsnap cache for instantaneous container boot.
- **Web Acceleration:** Served via Thruster (`./bin/thrust ./bin/rails server`) on port 80.
- **Security Hardening:** Runs under unprivileged `rails:rails` system user.

### 7.2 Entrypoint Workflow (`bin/docker-entrypoint`)
```bash
if [ "${1}" = "./bin/rails" ] || [ "${1}" = "./bin/thrust" ]; then
  ./bin/rails db:prepare
fi
```
Ensures database creation and pending migrations are automatically executed upon container launch.
