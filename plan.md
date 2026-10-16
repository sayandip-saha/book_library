# Book Library — Strategic Project Plan (`plan.md`)

## 1. Executive Summary & Vision

**Book Library** is an elegant, responsive personal library management system engineered with Ruby on Rails 8. The application allows bibliophiles, collectors, and small organizational libraries to catalog, organize, filter, and track physical and digital book collections with ease.

The project pairs robust relational modeling (books, authors, categories, users, sessions) and referential integrity with an ultra-responsive dark glassmorphism user interface powered by Google Fonts, CSS3 tokens, and zero-overhead native asset delivery.

---

## 2. Project Goals & Objectives

| Objective | Target | Status |
| :--- | :--- | :--- |
| **Catalog Management** | Complete CRUD operations for books with ISBN, publication year, description, and status | ✅ Complete |
| **Taxonomy & Relational Integrity** | Manage authors and categories with strict foreign keys and deletion safeguards | ✅ Complete |
| **Discovery & Search** | Multi-attribute querying by sanitized keyword, author filter, and category filter | ✅ Complete |
| **User Authentication** | Rails 8 native auth with session management, rate-limiting, and password recovery | ✅ Complete |
| **Public vs. Protected Access** | Public catalog reading; protected write access requiring account sign-in | ✅ Complete |
| **Performance & Optimization** | N+1 query elimination via eager loading (`includes`) across all listings | ✅ Complete |
| **Modern User Experience** | Dark-mode glassmorphic interface, Google Fonts, 3D book mockups, toggle controls | ✅ Complete |
| **Deployment Readiness** | Containerized Rails 8 stack with Thruster, Kamal, and SQLite3 | ✅ Complete |

---

## 3. Scope Definition

### 3.1 In Scope (Current Baseline)
- **Books Module:**
  - Create, view, update, and delete book entries.
  - Track availability status (Available vs. Borrowed) via interactive toggle controls.
  - Validation rules for title presence, publication year presence, and ISBN uniqueness.
  - Eager loading (`includes(:author, :category)`) to prevent N+1 database queries.
- **Authors & Categories Taxonomy:**
  - Create and list authors and genres with real-time book counter badges.
  - One-click filter links from taxonomy cards directly to the filtered catalog.
  - Deletion protection (`dependent: :restrict_with_error`) preventing orphaned books.
- **Authentication & Security Module:**
  - Rails 8 built-in authentication using `has_secure_password` (BCrypt).
  - Secure session tracking (`Session`, `Current.user`) with signed HTTP-only cookies.
  - Password recovery with expiring reset tokens and `Action Mailer` delivery.
  - Rate limiting on sensitive authentication endpoints (10 attempts per 3 minutes).
  - Public catalog browsing (`allow_unauthenticated_access`); authenticated book mutation.
- **Dashboard & Search:**
  - Sanitized title search preventing SQL injection and wildcard manipulation.
  - Author and category dropdown filters.
  - Collection metrics grid (Total Books, Featured Authors, Genres).
- **Design System & UI:**
  - Custom glassmorphism dark theme with `Plus Jakarta Sans` and `Outfit` fonts.
  - 3D book spine/cover mockups with ISBN barcode chips.
  - 2-column detailed book showcase layout with reading synopsis card.
  - Global glassmorphic flash notification toast alerts (`notice` & `alert`).

### 3.2 Out of Scope (Future Phases)
- Patron/borrower checkout ledger with loan duration and due dates (Phase 2).
- Automatic overdue email alerts via `Solid Queue` (Phase 2).
- Automated book cover and metadata fetching via Open Library / Google Books API (Phase 3).
- Barcode/ISBN scanning via mobile camera (Phase 3).
- Data export/import (CSV, JSON, BibTeX) (Phase 4).

---

## 4. Architectural Blueprint

```
+-------------------------------------------------------------------------------+
|                                 Client Layer                                  |
|   Responsive Dark Glassmorphism UI (HTML5 / Modern CSS / Turbo / Google Fonts)|
+---------------------------------------+---------------------------------------+
                                        |
                                        v HTTP / REST
+-------------------------------------------------------------------------------+
|                            Rails 8 Application Layer                          |
|   +-------------------+  +---------------------+  +-------------------------+ |
|   |  BooksController  |  |  AuthorsController  |  |  CategoriesController   | |
|   +---------+---------+  +----------+----------+  +------------+------------+ |
|   |  UsersController  |  |  SessionsController |  |   PasswordsController   | |
|   +---------+---------+  +----------+----------+  +------------+------------+ |
|             |                       |                          |              |
|             +-----------------------+--------------------------+              |
|                                     |                                         |
|   +-------------------+  +----------+----------+  +-------------------------+ |
|   |     Book Model    |  |   Author Model      |  |     Category Model      | |
|   +-------------------+  +---------------------+  +-------------------------+ |
|   |     User Model    |  |   Session Model     |  |   Current Attributes    | |
|   +-------------------+  +---------------------+  +-------------------------+ |
+---------------------------------------+---------------------------------------+
                                        |
                                        v Active Record
+-------------------------------------------------------------------------------+
|                                  Data Layer                                   |
|       SQLite3 Database (books, authors, categories, users, sessions)          |
|       Solid Cache / Solid Queue / Solid Cable                                 |
+-------------------------------------------------------------------------------+
```

---

## 5. Development Phases & Roadmap

```
Phase 1: Core Foundation & UI System [COMPLETE]
   └── Rails 8 scaffold, SQLite migrations, models, validations, REST controllers,
       Modern Dark UI theme, Google Fonts, 3D book mockups, search filters.

Phase 2: Authentication & Member Base [COMPLETE]
   └── Built-in Rails 8 auth, BCrypt password hashing, session cookies,
       rate limiting, password reset mailer, public vs protected permissions.

Phase 3: Circulation & Loan Ledger [NEXT]
   ├── Borrowing model (user_id, book_id, borrowed_at, due_date, returned_at)
   ├── Automated toggle of Book#available based on active loans
   ├── "My Borrowed Books" patron dashboard
   └── Overdue notifications using Solid Queue and Action Mailer.

Phase 4: External Integrations & Media [PLANNED]
   ├── Active Storage for uploaded book cover images
   ├── Open Library API client for auto-filling ISBN metadata
   └── Web camera barcode scanner (QuaggaJS / ZXing).

Phase 5: Advanced Analytics & Portability [FUTURE]
   ├── CSV & JSON bulk catalog import/export
   ├── Reading goals and category distribution charts
   └── PWA offline reading list.
```

---

## 6. Risk Management & Mitigations

| Risk | Impact | Probability | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **Referential Integrity Violation** | High | Low | Enforced at DB level with `add_foreign_key` and at model level with `dependent: :restrict_with_error`. |
| **Duplicate ISBN Entry** | Medium | Medium | Database uniqueness constraint and Active Record `validates :isbn, uniqueness: true`. |
| **N+1 Query Inefficiencies** | Medium | Low | Controller query optimization with eager loading (`includes(:author, :category)` and `includes(:books)`). |
| **Unauthorized Data Modification** | High | Low | Global `require_authentication` default with granular `allow_unauthenticated_access` only for public read actions. |
| **Brute Force & Credential Attacks**| High | Low | Native `rate_limit to: 10, within: 3.minutes` on sessions and passwords endpoints. |
| **Single Point of Failure (SQLite)**| Medium | Low | Use Rails 8 Solid utilities (`solid_cache`, `solid_queue`), automated volume backups, and WAL mode. |

---

## 7. Quality Assurance & Acceptance Criteria

1. **CRUD Verification:** Every book, author, and category can be created, inspected, updated, and deleted by authenticated users.
2. **Deletion Guardrails:** An author or category that has associated books cannot be deleted; the user receives a clear validation error alert.
3. **Authentication Flows:** Users can register, sign in, sign out, and initiate secure password resets with 15-minute token expiry.
4. **Public Browsing:** Visitors can browse the catalog and view book details without logging in; mutations redirect to login.
5. **Search Performance:** Sanitized search by substring in title and filtering by dropdown selectors yields instant, accurate results without N+1 queries.
6. **Form Validation:** Incomplete submissions display accessible inline error banners with HTTP 422 Unprocessable Entity status.
7. **Responsive Glassmorphism:** The interface adjusts smoothly across mobile (<680px), tablet (680px-960px), and desktop displays.
