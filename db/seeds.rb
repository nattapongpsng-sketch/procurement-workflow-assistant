# Loads reference data, document templates and workflows from db/seeds/**.yml.
# Idempotent — run `bin/rails db:seed` as often as you like.
workflows = SeedLoader.call

puts "Recommended AI: #{RecommendedAi.count} · People: #{Person.count} · Budget sources: #{BudgetSource.count}"
puts "Document templates: #{DocumentTemplate.pluck(:code, :version).map { |c, v| "#{c} v#{v}" }.join(', ')}"
workflows.each do |w|
  puts "Workflow: #{w.code} v#{w.version} (#{w.status}) — #{w.workflow_steps.count} steps, #{w.field_definitions.count} fields"
end

if Rails.env.development?
  password = ENV.fetch("DEV_USER_PASSWORD", "dev-password-1234")
  users = SeedLoader.load_development_users(password:)
  puts "Development users (password: #{password}): #{users.map(&:email_address).join(', ')}"
end
