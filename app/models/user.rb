class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }

  def role_title
    admin? ? "Administrator" : "Reader"
  end

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end
end
