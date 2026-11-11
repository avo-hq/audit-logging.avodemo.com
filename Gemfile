source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.1", ">= 7.2.1.1"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 1.4"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

AVO_ADD_ONS = %w[
  avo-licensing avo-authorization avo-dashboards avo-menu avo-advanced_search avo-record_reordering avo-scopes
  avo-custom_controls avo-dynamic_filters avo-nested avo-audit_logging avo-api avo-mcp_server avo-ai
].freeze

# AVO_GEMS_PATH bundles unreleased add-ons from a workspace checkout. Set it only through an uncommitted
# Gemfile.local (BUNDLE_GEMFILE=Gemfile.local), so Gemfile.lock keeps resolving from packager.dev.
if (local_gems = ENV["AVO_GEMS_PATH"])
  gem "avo", path: ENV.fetch("AVO_CORE_PATH")
  AVO_ADD_ONS.each { |name| gem name, path: File.join(local_gems, name) }
else
  gem "avo", ">= 4.4.3"

  source "https://packager.dev/avo-hq/" do
    # The audit log the tour walks through (its list, activity page and impacted records) is 4.4.1's.
    AVO_ADD_ONS.each { |name| gem name, (name == "avo-audit_logging") ? ">= 4.4.1" : ">= 4.4.0" }
  end
end

# avo-dynamic_filters configures Ransack at boot but does not require it.
gem "ransack"
# avo-mcp_server allows mcp ~> 1.1, but its handle_json override rejects the auth_info: newer mcp passes.
gem "mcp", "~> 1.5.0"
gem "devise", "~> 4.9"
# Rails' own words (dates, "3 days ago", plural rules) in the languages the panel's switcher offers.
gem "rails-i18n"
gem "tailwindcss-rails", "~> 4.0"
# The dashboard's chart cards.
gem "chartkick"
gem "progressbar", "~> 1.13"
gem "factory_bot_rails", "~> 6.2"
gem "faker", "~> 3.1", ">= 3.1.1"
gem "annotate", "~> 3.2"
gem "pretender", "~> 0.5.0"


gem "paper_trail", "~> 17.0"

# Money field and monetization
gem "avo-money_field"
gem "money-rails", "~> 1.12"
