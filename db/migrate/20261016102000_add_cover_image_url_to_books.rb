class AddCoverImageUrlToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :cover_image_url, :string
  end
end

