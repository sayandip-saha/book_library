# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Default Administrator Accounts
admin_accounts = [
  { email_address: "admin@booklibrary.com", password: "password123" },
  { email_address: "sayandip@booklibrary.com", password: "password123" },
  { email_address: "librarian@booklibrary.com", password: "password123" }
]

admin_accounts.each do |admin_data|
  user = User.find_or_initialize_by(email_address: admin_data[:email_address])
  user.password = admin_data[:password]
  user.password_confirmation = admin_data[:password]
  user.admin = true
  user.save!
  puts "Seeded Admin: #{user.email_address}"
end
