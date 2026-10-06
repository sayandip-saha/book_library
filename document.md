# Book Library — Comprehensive Documentation (`document.md`)

## 1. Introduction & Overview

**Book Library** is an application built with Ruby on Rails 8 designed to catalog, organize, and monitor book collections. It pairs a database with an ultra-responsive dark glassmorphism interface.

### Key Capabilities
- **Book Cataloging:** Complete metadata tracking (Title, Author, Category, ISBN, Publication Year, Synopsis, Availability).
- **Taxonomy Management:** Dedicated Author and Category indexes with active relationship tracking.
- **Search & Filtering:** Real-time multi-dimensional search filtering books simultaneously by title query, author, and category.
- **Safety Controls:** Referential deletion protection (`restrict_with_error`) ensuring authors or categories cannot be orphaned while books are assigned.
- **Modern Dark UI:** Glassmorphism design system built with native CSS, custom properties, and responsive grid layouts.

---

## 2. End-User Guide

### 2.1 Navigation & Dashboard
The top navigation bar provides instant access to key sections:
- **Logo / Brand:** Returns to the main library dashboard (`/books`).
- **Books:** Opens the master catalog and search portal.
- **Authors:** Opens the author management directory.
- **Categories:** Opens the category and genre directory.
- **+ Add Book:** Quick shortcut to register a new book into the library.

### 2.2 Metrics & Overview
At the top of the collection page, the stats grid displays live aggregate totals:
- **BOOKS:** Total number of books cataloged.
- **AUTHORS:** Total number of registered authors.
- **CATEGORIES:** Total number of categories and genres.

### 2.3 Searching and Filtering Books
Under the header stats, use the **Search Panel**:
1. **Search Books:** Type any keyword or phrase into the text field to match book titles.
2. **Author Dropdown:** Filter specifically by a chosen author or select "All Authors".
3. **Category Dropdown:** Filter by category or select "All Categories".
4. **Submit:** Click **Search** to execute the combined filter.
5. **Reset:** Click **Clear Filters** to return to the full collection view.

### 2.4 Adding a Book
1. Click **+ Add Book** in the navigation header or hero section.
2. Fill out the book details:
   - **Book Title** *(Required)*: The title of the publication.
   - **Author** *(Required)*: Select an existing author from the dropdown. *(Tip: If the author does not exist, create them first via the Authors tab).*
   - **Category** *(Required)*: Select an existing category. *(Tip: Add missing categories via the Categories tab).*
   - **ISBN** *(Required & Unique)*: The 10 or 13-digit International Standard Book Number.
   - **Publication Year** *(Required)*: Four-digit year of release (e.g., `2024`).
   - **Description**: Summary, jacket copy, or notes about the book.
   - **Available Checkbox**: Check if the book is currently on the shelf; uncheck if it is borrowed or checked out.
3. Click **Create Book**. If validations fail, an error notification highlights missing or duplicate fields.

### 2.5 Inspecting & Editing Books
- **Inspect:** Click on any book card or the **View** button to open the detailed view (`/books/:id`), displaying full metadata, publication year, ISBN, and description.
- **Edit:** Click **Edit** from the book card or show page to modify metadata or toggle availability status.
- **Delete:** From the book show page, click **Delete Book**. Confirm the prompt to remove the book permanently from the catalog.

### 2.6 Managing Authors
- Navigate to **Authors** (`/authors`).
- Review the total number of books assigned to each author.
- Click **+ Add Author** to create a new author name.
- **Delete Author Safeguard:** If an author has books associated with them, attempting to delete them will be blocked with an informative message (`Cannot delete record because dependent books exist`). To delete an author, you must first reassign or delete their associated books.

### 2.7 Managing Categories
- Navigate to **Categories** (`/categories`).
- View the book count for each genre or category.
- Click **+ Add Category** to register new categories (e.g., *Science Fiction*, *History*, *Philosophy*).
- **Delete Category Safeguard:** Similarly to authors, categories with existing books are protected from accidental removal.

---

## 3. Developer & Contributor Guide

### 3.1 System Requirements
- **Ruby:** `3.4.10` (or compatible Ruby 3.3+)
- **Rails:** `8.1.3` or later
- **SQLite3:** Version 3.40+ with WAL mode support
- **Bundler:** Version 2.5+

### 3.2 Local Setup
Clone the repository and set up dependencies:

```bash
# 1. Clone repository
git clone https://github.com/sayandip-saha/book_library.git
cd book_library

# 2. Automated Rails setup (installs gems, creates & migrates database)
bin/setup

# 3. Start development server
bin/rails server
# Or using the dev script:
bin/dev
```

The application will be accessible at `http://localhost:3000`.

### 3.3 Database Operations
```bash
# Run pending migrations
bin/rails db:migrate

# Inspect migration status
bin/rails db:migrate:status

# Reset database (drop, create, migrate, seed)
bin/rails db:reset

# Access Rails interactive console
bin/rails console
```

### 3.4 Automated Testing & Code Quality
```bash
# Run all model and controller tests
bin/rails test

# Run Rails integration/system tests
bin/rails test:system

# Code linting with RuboCop
bin/rubocop

# Security vulnerability analysis with Brakeman
bin/brakeman

# Dependency vulnerability auditing
bin/bundler-audit

# Unified CI test suite
bin/ci
```

---

## 4. API & Routing Specifications

The application follows RESTful Rails resource conventions:

| HTTP Verb | Path | Controller#Action | Description |
| :--- | :--- | :--- | :--- |
| **GET** | `/` | `books#index` | Application homepage / book list |
| **GET** | `/books` | `books#index` | Master book catalog with search parameters |
| **GET** | `/books/new` | `books#new` | New book creation form |
| **POST** | `/books` | `books#create` | Persists a new book record |
| **GET** | `/books/:id` | `books#show` | Detailed view for a single book |
| **GET** | `/books/:id/edit` | `books#edit` | Book modification form |
| **PATCH/PUT** | `/books/:id` | `books#update` | Updates an existing book |
| **DELETE** | `/books/:id` | `books#destroy` | Deletes a book record |
| **GET** | `/authors` | `authors#index` | Directory of authors with book counts |
| **GET** | `/authors/new` | `authors#new` | Author creation form |
| **POST** | `/authors` | `authors#create` | Persists a new author |
| **DELETE** | `/authors/:id` | `authors#destroy` | Safely removes an author (if unlinked) |
| **GET** | `/categories` | `categories#index` | Directory of categories with book counts |
| **GET** | `/categories/new` | `categories#new` | Category creation form |
| **POST** | `/categories` | `categories#create` | Persists a new category |
| **DELETE** | `/categories/:id` | `categories#destroy` | Safely removes a category (if unlinked) |

---

## 5. Deployment & Production Operations

### 5.1 Docker Container Deployment
The application includes a production-ready, multi-stage `Dockerfile`:

```bash
# 1. Build the production Docker container
docker build -t book_library:latest .

# 2. Run the container with master key and port mapping
docker run -d \
  -p 80:80 \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  -v book_library_data:/rails/storage \
  --name book_library \
  book_library:latest
```

### 5.2 Kamal Deployment
The application is pre-configured for deployment with [Kamal](https://kamal-deploy.org):
```bash
# Initial server setup
bin/kamal setup

# Deploy latest changes
bin/kamal deploy
```

---

## 6. Frequently Asked Questions (FAQ)

#### Q: Why can't I delete an author or category?
**A:** This is an intentional data safety mechanism configured in `app/models/author.rb` and `app/models/category.rb` (`dependent: :restrict_with_error`). To delete an author or category, you must first delete or reassign all books linked to it.

#### Q: How is search handled?
**A:** Search runs server-side through parameterized Active Record queries on `Book#title`, `Book#author_id`, and `Book#category_id`. Searching is instant, sanitizes inputs, and avoids client-side memory overhead.

#### Q: What happens if I enter a duplicate ISBN?
**A:** Active Record enforces uniqueness on the `isbn` attribute (`validates :isbn, presence: true, uniqueness: true`). The submission will be rejected with an inline validation alert explaining that the ISBN has already been taken.
