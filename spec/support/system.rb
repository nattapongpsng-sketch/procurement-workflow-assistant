RSpec.configure do |config|
  # Smoke specs run without a browser; tag `js: true` to use headless Chrome.
  config.before(:each, type: :system) { driven_by :rack_test }
  config.before(:each, type: :system, js: true) { driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] }
end
