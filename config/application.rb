require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Radarmatic
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.active_record.sqlite3.represent_boolean_as_integer = true
    config.base_radar_url = "http://tgftp.nws.noaa.gov/SL.us008001/DF.of/DC.radar"

    config.cache_store = ActiveSupport::Cache::MemoryStore.new(size: 128.megabytes)
    config.action_controller.perform_caching = true
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{1.year.to_i}",
      "Expires" => "#{1.year.from_now.httpdate}",
      "X-Warning" => "HC SVNT DRACONES"
    }
  end
end
