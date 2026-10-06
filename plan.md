# Book Library — Strategic Project Plan (`plan.md`)

## 1. Executive Summary & Vision

**Book Library** is an elegant, responsive personal library management system built with Ruby on Rails 8. The application allows bibliophiles, collectors, and small organizational libraries to catalog, organize, filter, and track physical and digital book collections with ease.

The project pairs robust relational modeling (books, authors, categories) and referential integrity with a high-performance modern dark glassmorphism user interface.

---

## 2. Project Goals & Objectives

| Objective | Target | Status |
| :--- | :--- | :--- |
| **Catalog Management** | Complete CRUD operations for books with ISBN, publication year, description, and status | ✅ Complete |
| **Taxonomy & Relational Integrity** | Manage authors and categories with strict foreign keys and deletion safeguards | ✅ Complete |
| **Discovery & Search** | Multi-attribute querying by keyword, author dropdown, and category dropdown | ✅ Complete |
| **Real-Time Collection Metrics** | Live dashboard metrics (total books, authors, categories) | ✅ Complete |
| **Modern User Experience** | Dark-mode glassmorphic interface, responsive layout, no bloated JS frameworks | ✅ Complete |
| **Deployment Readiness** | Containerized Rails 8 stack with Thruster, Kamal, and SQLite3 | ✅ Complete |

---

## 3. Scope Definition

### 3.1 In Scope (Current Baseline)
- **Books Module:**
  - Create, view, update, and delete book entries.
  - Track availability status (Available vs. Borrowed).
  - Validation rules for title presence, publication year presence, and ISBN uniqueness.
- **Authors Module:**
  - Create and list authors with associated book counters.
  - Delete authors with deletion protection (`dependent: :restrict_with_error`).
- **Categories Module:**
  - Create and list categories/genres with book counts.
  - Delete categories with deletion protection (`dependent: :restrict_with_error`).
- **Dashboard & Search:**
  - Search books by title keyword.
  - Filter books by author and category.
  - Aggregate statistics at the top of the collection view.
- **Production Containerization:**
  - Dockerfile with multi-stage build, jemalloc memory optimization, bootsnap precompilation, and Thruster acceleration.

### 3.2 Out of Scope (Future Phases)
- Multi-user authentication & role-based permissions (Phase 2).
- Patron/borrower checkout history and due date tracking (Phase 2).
- Automated book cover and metadata fetching via Open Library / Google Books API (Phase 3).
- Barcode/ISBN scanning via mobile camera (Phase 3).
- Data export/import (CSV, JSON, BibTeX) (Phase 4).

---

## 4. Architectural Blueprint

```
+------------------------------------------------------------------------+
|                              Client Layer                              |
|   Responsive Dark UI (HTML5 / Modern CSS Glassmorphism / Hotwire Turbo)|
+------------------------------------+-----------------------------------+
                                     |
                                     v HTTP / REST
+------------------------------------------------------------------------+
|                         Rails 8 Application Layer                       |
|   +-------------------+  +---------------------+  +------------------+ |
|   |  BooksController  |  |  AuthorsController  |  |CategoriesContr...| |
|   +---------+---------+  +----------+----------+  +--------+---------+ |
|             |                       |                      |           |
|             +-----------------------+----------------------+           |
|                                     |                                  |
|   +-------------------+  +----------+----------+  +------------------+ |
|   |     Book Model    |  |   Author Model      |  |  Category Model  | |
|   +-------------------+  +---------------------+  +------------------+ |
+------------------------------------+-----------------------------------+
                                     |
                                     v Active Record
+------------------------------------------------------------------------+
|                             Data Layer                                 |
|            SQLite3 Database (books, authors, categories)               |
|            Solid Cache / Solid Queue / Solid Cable                     |
+------------------------------------------------------------------------+
```

---

## 5. Development Phases & Roadmap

```
Phase 1: Core Foundation [DONE]
   └── Rails 8 scaffold, SQLite migrations, models, validations, REST controllers, Dark UI theme.

Phase 2: Member & Circulation Tracking [NEXT]
   ├── User Authentication (Rails 8 built-in auth / Devise)
   ├── Patron & borrower entity modeling
   └── Circulation ledger: Check-out, Check-in, Due dates, Overdue notifications.

Phase 3: External Integrations & Media [PLANNED]
   ├── Active Storage for book cover images
   ├── Open Library & Google Books API client for auto-filling ISBN metadata
   └── Web camera barcode scanner (QuaggaJS / ZXing).

Phase 4: Advanced Analytics & Data Portability [FUTURE]
   ├── CSV & JSON bulk import/export
   ├── Reading goal tracker & statistics
   └── PWA offline-first reading list.
```

### Detailed Phase Breakdown

#### Phase 1: Core Foundation (Current Baseline)
- Data schemas for `books`, `authors`, `categories`.
- Strict foreign key constraints and model validations.
- BooksController index search filter pipeline (`query`, `author_id`, `category_id`).
- Custom styling system (`application.css`) featuring custom CSS properties, blur filters, and responsive layouts.
- Production-ready Dockerfile and Thruster server integration.

#### Phase 2: Circulation & Member Management
- Introduce `Patron` or `User` model.
- Introduce `Borrowing` join model:
  - `book_id`, `patron_id`, `borrowed_at`, `due_date`, `returned_at`.
- Automated toggle of `Book#available` based on open borrowings.
- Overdue tracking and email alerts using `Solid Queue` and `Action Mailer`.

#### Phase 3: Metadata Automation & Media
- Integrate `Active Storage` for book cover attachments.
- Background worker to query Open Library API via ISBN (`https://openlibrary.org/isbn/{isbn}.json`) to populate synopsis, cover image, and publisher.

#### Phase 4: Portability & Analytics
- Data export in CSV, JSON, and Goodreads-compatible format.
- Interactive charts (books added per month, category distribution) using Chart.js or Stimulus controllers.

---

## 6. Risk Management & Mitigations

| Risk | Impact | Probability | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **Referential Integrity Violation** | High | Low | Enforced at DB level with `add_foreign_key` and at model level with `dependent: :restrict_with_error`. |
| **Duplicate ISBN Entry** | Medium | Medium | Database uniqueness constraint and Active Record `validates :isbn, uniqueness: true`. |
| **N+1 Query Inefficiencies** | Medium | Low | Controller query optimization with eager loading (`includes(:author, :category)`) during book listing. |
| **High Memory in Container** | Medium | Low | Use `jemalloc2` preloaded via Dockerfile `LD_PRELOAD` and `bootsnap` precompilation. |
| **Single Point of Failure (SQLite)** | Medium | Low | Use Rails 8 Solid utilities (`solid_cache`, `solid_queue`), automated volume backups, or Litestream for continuous S3 replication. |

---

## 7. Quality Assurance & Acceptance Criteria

1. **CRUD Verification:** Every book, author, and category can be created, inspected, updated, and deleted.
2. **Deletion Guardrails:** An author or category that has associated books cannot be deleted; the user receives a clear validation error.
3. **Search Responsiveness:** Search by substring in title and filtering by dropdown selectors yields instant, accurate results.
4. **Form Error Handling:** Incomplete submissions (missing title, duplicate ISBN) display accessible inline error banners with HTTP 422 Unprocessable Entity status.
5. **Responsive Viewport Support:** The user interface adjusts seamlessly across mobile (<650px), tablet (650px-950px), and desktop displays.
