# Book Library — Comprehensive Documentation (`document.md`)

## 1. Introduction & Overview

**Book Library** is an application built with Ruby on Rails 8 designed to catalog, organize, and monitor physical and digital book collections. It combines a relational SQLite database with a modern dark glassmorphism interface.

### Key Capabilities
- **Book Cataloging:** Complete metadata tracking (Title, Author, Category, ISBN, Publication Year, Synopsis, Availability).
- **Authentication & Security:** Built-in Rails 8 authentication with secure password hashing (BCrypt), session cookie tracking, rate limiting, and email-based password recovery.
- **Public Discovery & Protected Modification:** Visitors can freely browse and search the collection; creating, editing, and deleting records requires logging in.
- **Taxonomy Management:** Dedicated Author and Category directories with one-click collection filtering.
- **Search & Filtering:** Real-time multi-dimensional search filtering books simultaneously by sanitized title keywords, author, and category.
- **Safety Controls:** Referential deletion protection (`restrict_with_error`) ensuring authors or categories cannot be deleted while books are assigned.
- **Modern Dark UI:** Glassmorphism design system built with Google Fonts (`Plus Jakarta Sans`, `Outfit`), CSS custom properties, 3D book cover mockups, and responsive layouts.

---

## 2. End-User Guide

### 2.1 Navigation & User Profiles
The sticky top navigation bar provides instant access across the application:
- **Logo / Brand (`📚 BookLibrary`):** Returns to the main library catalog (`/books`).
- **Books:** Opens the master catalog and search portal.
- **Authors:** Opens the author directory.
- **Categories:** Opens the category and genre directory.
- **User Profile Pill (`user@example.com`):** When signed in, displays your account email and initial avatar.
- **+ Add Book:** Shortcut to register a new book (requires sign-in).
- **Log In / Create Account:** Accessible to visitors in the top right.
- **Log Out:** Securely terminates the session and returns to the login screen.

### 2.2 Account Creation & Password Recovery
1. **Registration:**
   - Click **Create Account** in the navbar or visit `/users/new`.
   - Enter your email address and a secure password.
   - Upon registration, your session is immediately authenticated and you are directed to the catalog.
2. **Logging In:**
   - Click **Log In** or visit `/session/new`.
   - Enter your credentials. If you attempted to access a protected page (like adding a book), you will automatically be redirected there after logging in.
3. **Password Reset:**
   - Click **Forgot password?** on the login form or visit `/passwords/new`.
   - Submit your registered email address.
   - If the account exists, password reset instructions with a secure 15-minute token will be dispatched to your inbox.
   - Click the link in the email to set a new password.

### 2.3 Metrics & Overview
At the top of the collection page, the stats grid displays live aggregate totals:
- **TOTAL BOOKS:** Count of all books cataloged in the library.
- **FEATURED AUTHORS:** Count of distinct authors represented.
- **GENRES & CATEGORIES:** Count of active thematic categories.

### 2.4 Searching and Filtering Books
Under the header stats, use the **Filter Collection Command Bar**:
1. **Search Title:** Type any keyword or title fragment. Search queries are automatically sanitized.
2. **Author Dropdown:** Filter by a chosen author or select "All Authors".
3. **Category Dropdown:** Filter by genre or select "All Categories".
4. **Submit:** Click **Apply Filters** to update the list. The counter displays how many books match.
5. **Reset:** Click **Clear Filters** to quickly reset all criteria.

### 2.5 Adding a Book (Requires Authentication)
1. Click **+ Add Book** in the navigation header or hero section.
2. Fill out the book details:
   - **Book Title** *(Required)*: The full title of the publication.
   - **Author** *(Required)*: Select an existing author from the dropdown. *(Tip: Add missing authors via the Authors directory).*
   - **Category** *(Required)*: Select a genre or category. *(Tip: Add missing genres via the Categories directory).*
   - **ISBN** *(Required & Unique)*: The 10 or 13-digit International Standard Book Number.
   - **Publication Year** *(Required)*: Four-digit year of release (e.g., `2024`).
   - **Synopsis & Catalog Notes**: Summary, impressions, or jacket copy.
   - **Circulation Availability Toggle**: Slide toggle on if the book is currently on the shelf; toggle off if borrowed or lent out.
3. Click **✨ Create Book Entry**. An inline error banner highlights any missing or duplicate fields.

### 2.6 Inspecting & Editing Books
- **Inspect:** Click on any book card or **View Details →** to open the 2-column showcase view (`/books/:id`), displaying the 3D cover card, circulation status, ISBN barcode chip, author strip, specifications grid, and reading synopsis.
- **Edit:** Click **Edit** from the book card or show page to modify metadata or toggle availability.
- **Delete:** From the book show page, click **🗑️ Delete Book** and confirm the prompt.

### 2.7 Managing Authors
- Navigate to **Authors** (`/authors`).
- Review author cards showing initial avatars and the number of books in the collection.
- Click **View Books** on any author card to instantly filter the library catalog to that author's works.
- Click **+ Add Author** to register a new author.
- **Delete Safeguard:** If an author has books associated with them, attempting to delete them is blocked with a protective alert (`Cannot delete record because dependent books exist`).

### 2.8 Managing Categories
- Navigate to **Categories** (`/categories`).
- View category cards with genre badges and book counts.
- Click **View Books** on any category card to filter the catalog by that genre.
- Click **+ Add Category** to register new categories (e.g., *Science Fiction*, *Philosophy*, *Biography*).
- **Delete Safeguard:** Categories with linked books are protected from accidental removal.

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

| HTTP Verb | Path | Controller#Action | Access Level | Description |
| :--- | :--- | :--- | :--- | :--- |
| **GET** | `/` | `books#index` | Public | Homepage / book catalog |
| **GET** | `/books` | `books#index` | Public | Master book catalog with search parameters |
| **GET** | `/books/new` | `books#new` | Authenticated | New book creation form |
| **POST** | `/books` | `books#create` | Authenticated | Persists a new book record |
| **GET** | `/books/:id` | `books#show` | Public | 2-column detailed showcase view |
| **GET** | `/books/:id/edit` | `books#edit` | Authenticated | Book modification form |
| **PATCH/PUT** | `/books/:id` | `books#update` | Authenticated | Updates an existing book |
| **DELETE** | `/books/:id` | `books#destroy` | Authenticated | Deletes a book record |
| **GET** | `/authors` | `authors#index` | Public | Directory of authors with book counts |
| **GET** | `/authors/new` | `authors#new` | Authenticated | Author creation form |
| **POST** | `/authors` | `authors#create` | Authenticated | Persists a new author |
| **DELETE** | `/authors/:id` | `authors#destroy` | Authenticated | Safely removes an author (if unlinked) |
| **GET** | `/categories` | `categories#index` | Public | Directory of categories with book counts |
| **GET** | `/categories/new` | `categories#new` | Authenticated | Category creation form |
| **POST** | `/categories` | `categories#create` | Authenticated | Persists a new category |
| **DELETE** | `/categories/:id` | `categories#destroy` | Authenticated | Safely removes a category (if unlinked) |
| **GET** | `/users/new` | `users#new` | Public | User account sign-up form |
| **POST** | `/users` | `users#create` | Public | Registers user and starts session |
| **GET** | `/session/new` | `sessions#new` | Public | Sign-in authentication form |
| **POST** | `/session` | `sessions#create` | Public | Authenticates credentials and issues cookie |
| **DELETE** | `/session` | `sessions#destroy` | Authenticated | Terminates user session |
| **GET** | `/passwords/new` | `passwords#new` | Public | Password reset request form |
| **POST** | `/passwords` | `passwords#create` | Public | Dispatches reset instructions email |
| **GET** | `/passwords/:token/edit` | `passwords#edit` | Public | Password reset form with token verification |
| **PATCH/PUT** | `/passwords/:token` | `passwords#update` | Public | Sets new password and clears sessions |

---

## 5. Deployment & Production Operations

### 5.1 Docker Container Deployment
```bash
# 1. Build the production Docker container
docker build -t book_library:latest .

# 2. Run the container with master key and storage volume mapping
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

#### Q: Do I need to create an account to browse the library?
**A:** No. Browsing books, viewing individual book details, searching, and viewing authors or categories are publicly accessible to all visitors. Creating an account or signing in is only required when you want to add, edit, or delete catalog records.

#### Q: Why can't I delete an author or category?
**A:** This is an intentional data safety mechanism configured in `app/models/author.rb` and `app/models/category.rb` (`dependent: :restrict_with_error`). To delete an author or category, you must first reassign or delete all books associated with it.

#### Q: How does password recovery work?
**A:** Password resets use Rails 8 `generates_token_for :password_reset`. When requested, a signed token is generated with a 15-minute expiration window. The token is tied to your password salt, meaning once a password is changed, all previous reset links immediately become invalid.

#### Q: How does search handle special characters?
**A:** Search inputs are sanitized using `ActiveRecord::Base.sanitize_sql_like`, ensuring that wildcards such as `%` or `_` are treated as literal characters and parameterized Active Record queries prevent SQL injection.

#### Q: What happens if I enter a duplicate ISBN?
**A:** Both the database schema and Active Record model enforce uniqueness on `isbn` (`validates :isbn, presence: true, uniqueness: true`). A submission with a duplicate ISBN is safely rejected with an inline validation alert.
