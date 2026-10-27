module Admin
  class DashboardController < BaseController
    def index
      @total_books = Book.count
      @available_books = Book.where(available: true).count
      @borrowed_books = Book.where(available: false).count
      @availability_rate = @total_books.positive? ? ((@available_books.to_f / @total_books) * 100).round(1) : 0

      @total_authors = Author.count
      @total_categories = Category.count
      @total_users = User.count
      @admin_count = User.where(admin: true).count
      @active_sessions_count = Session.count

      # Storage & Cover metrics
      @s3_covers_count = Book.joins(:cover_image_attachment).count
      @url_covers_count = Book.where.not(cover_image_url: [nil, ""]).where.missing(:cover_image_attachment).count
      @fallback_covers_count = @total_books - @s3_covers_count - @url_covers_count
      @fallback_covers_count = 0 if @fallback_covers_count.negative?

      # Total Active Storage byte size
      @total_storage_bytes = ActiveStorage::Blob.sum(:byte_size)

      # Recent records
      @recent_books = Book.includes(:author, :category, cover_image_attachment: :blob).order(created_at: :desc).limit(8)
      @recent_users = User.includes(:sessions).order(created_at: :desc).limit(8)
    end

    def sync_covers
      unattached_books = Book.where.not(cover_image_url: [nil, ""]).where.missing(:cover_image_attachment)
      synced_count = 0
      failed_count = 0

      unattached_books.find_each do |book|
        begin
          book.send(:attach_cover_from_url)
          synced_count += 1 if book.cover_image.attached?
        rescue StandardError => e
          Rails.logger.warn "Failed to sync cover for Book ##{book.id}: #{e.message}"
          failed_count += 1
        end
      end

      if synced_count.positive?
        redirect_to admin_root_path, notice: "Successfully synced #{synced_count} #{'cover'.pluralize(synced_count)} to AWS S3!"
      elsif failed_count.positive?
        redirect_to admin_root_path, alert: "Encountered errors while syncing #{failed_count} #{'cover'.pluralize(failed_count)}."
      else
        redirect_to admin_root_path, notice: "All books with external covers are already uploaded to S3!"
      end
    end
  end
end

