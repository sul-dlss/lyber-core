# frozen_string_literal: true

# The following is required in config/boot.rb
# require 'rubygems'
# require 'bundler/setup'
# Bundler.require(:default)

# LyberCore::Boot.up(__dir__)

module LyberCore
  # Boots up the robot environment, including configuration, logging, clients, and Sidekiq.
  class Boot
    def self.up(config_dir)
      new(config_dir).perform
    end

    def initialize(config_dir)
      @config_dir = config_dir
    end

    def perform
      boot_config
      boot_dsa
      boot_cocina_models
      boot_sidekiq
    end

    def environment
      @environment ||= ENV['ROBOT_ENVIRONMENT'] ||= 'development'
    end

    def boot_config
      Config.setup do |config|
        config.const_name = 'Settings'
        config.use_env = true
        config.env_prefix = 'SETTINGS'
        config.env_separator = '__'
      end
      Config.load_and_set_settings(
        Config.setting_files(File.expand_path(config_dir), environment)
      )
    end

    private

    attr_reader :config_dir

    def robot_root
      @robot_root ||= File.expand_path("#{config_dir}/..")
    end

    def robot_log
      Sidekiq::Logger.new(File.join(robot_root, "log/#{environment}.log")).tap do |log|
        log.level = Logger::SEV_LABEL.index(ENV.fetch('ROBOT_LOG_LEVEL', nil)) || Logger::INFO
      end
    end

    def boot_dsa
      return unless Settings.dor_services&.url

      Dor::Services::Client.configure(url: Settings.dor_services.url,
                                      token: Settings.dor_services.token,
                                      enable_get_retries: true)
    end

    def boot_cocina_models
      Cocina::Models::Mapping::Purl.base_url = Settings.purl_url if Settings.purl_url
    end

    def boot_sidekiq
      return if environment == 'test'

      Sidekiq.configure_server do |config|
        config.logger = robot_log
        config.redis = { url: Settings.redis_url }
        # For Sidekiq Pro
        config.super_fetch!
      end
    end
  end
end
