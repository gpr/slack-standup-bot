require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

#log4r requirements
require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/datefileoutputter'
include Log4r

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FetchBot
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.active_job.queue_adapter = :delayed_job

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.assets.paths << Emoji.images_path
    config.assets.precompile << "emoji/**/*.png"

    config.paths.add File.join('app'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', '*')]

     #Disable standard logging
    config.log_level = :unknown

    # Load YAML configuration file
    log4r_config = YAML.load_file(File.join(Rails.root,'config', 'log4r.yml'))
    log_cfg = YamlConfigurator

    log_cfg['ENV'] = Rails.env
    log_cfg['APPNAME'] = Rails.application.class.parent_name

    log_cfg.decode_yaml( log4r_config['log4r_config'] )
    # Setup can be override in environment config files
  end
end
