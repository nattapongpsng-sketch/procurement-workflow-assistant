namespace :users do
  desc "Create the first admin: bin/rails users:create_admin EMAIL=... NAME=... (prints a random password)"
  task create_admin: :environment do
    email = ENV.fetch("EMAIL") { abort "EMAIL is required" }
    name = ENV.fetch("NAME") { abort "NAME is required" }
    password = SecureRandom.base58(20)
    user = User.find_or_initialize_by(email_address: email)
    abort "#{email} already exists" if user.persisted?

    user.update!(name:, roles: [ "admin" ], password:, active: true)
    puts "Created admin #{email}. Temporary password (shown once, change it after signing in): #{password}"
  end
end
