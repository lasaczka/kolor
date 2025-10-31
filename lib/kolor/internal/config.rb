# frozen_string_literal: true
require 'fileutils'
require_relative 'logger'

module Kolor
  # Kolor::Config handles configuration loading and initialization for Kolor.
  #
  # It supports Ruby-based config files located in the user's home directory:
  #   - `.kolorrc.rb` — preferred format
  #   - `.kolorrc` — optional alias
  #
  # The config file can define themes using `Kolor::Extra.theme`.
  # If no config is found, a default file is created automatically.
  #
  # @example Initialize and load config
  #   Kolor::Config.init
  #
  # @example Reload config manually
  #   Kolor::Config.reload!
  #
  # @example Access loaded themes
  #   Kolor::Config.themes_from_config
  #
  # @example Describe a theme
  #   Kolor::Config.describe_theme(:success)
  module Config
    HOME_PATH = ENV['HOME'] || ENV['USERPROFILE']
    CONFIG_FILE_RB = HOME_PATH ? File.expand_path("#{HOME_PATH}/.kolorrc.rb") : nil
    CONFIG_FILE_ALIAS = HOME_PATH ? File.expand_path("#{HOME_PATH}/.kolorrc") : nil

    class << self
      # Initializes configuration.
      # Creates a default config file if none exists, then loads it.
      #
      # @return [void]
      def init
        create_default_config unless config_exists?
        load_config
      end

      # Checks whether any supported config file exists.
      #
      # @return [Boolean] true if a config file is found, false otherwise
      def config_exists?
        !config_file_path.nil?
      end

      # Creates a default Ruby config file in the user's home directory.
      # Skips creation if a config already exists.
      # Logs warnings if HOME is missing or creation fails.
      #
      # @return [void]
      def create_default_config
        unless HOME_PATH
          Kolor::Logger.warn 'No home directory found'
          return
        end

        return unless find_existing_config_file.nil?

        begin
          if CONFIG_FILE_RB.nil?
            raise LoadError, 'Config path is invalid'
          end
          FileUtils.cp(default_config_path, CONFIG_FILE_RB)
          Kolor::Logger.warn "Created default configuration file at #{CONFIG_FILE_RB}"
        rescue StandardError, LoadError => e
          Kolor::Logger.warn "Failed to create default config file: #{e.message}" if e.is_a?(StandardError)
          Kolor::Logger.warn e.message if e.is_a?(LoadError)
        end
      end

      # Loads configuration from disk.
      # Supports only Ruby-based config files (.rb or .kolorrc).
      # Logs info and warnings during the process.
      #
      # @return [void]
      def load_config
        config_path = config_file_path

        Kolor::Logger.info "load_config called, config_path: #{config_path.inspect}"

        return unless config_path

        Kolor::Logger.info "Loading config from: #{config_path}"

        if config_path.end_with?('.rb') || config_path.end_with?('.kolorrc')
          Kolor::Logger.info "Detected Ruby config"
          load_ruby_config(config_path)
        else
          Kolor::Logger.warn "Unknown config file type: #{config_path}"
        end
      rescue StandardError => e
        Kolor::Logger.warn "Error loading config file #{config_path}: #{e.message}"
      end

      # Reloads configuration from disk.
      #
      # @return [void]
      def reload!
        load_config
      end

      # Returns the theme configuration as a hash.
      #
      # @param name [Symbol, String] theme name
      # @return [Hash{Symbol => Object}, nil] theme config or nil if not found
      def describe_theme(name)
        Kolor::Extra.get_theme(name.to_sym)
      end

      # Returns all theme names loaded from config.
      #
      # @return [Array<Symbol>] list of theme keys
      def themes_from_config
        Kolor::Extra.themes
      end

      private

      # Returns the absolute path to the default config template.
      #
      # @return [String] path to default .kolorrc.rb file
      def default_config_path
        File.expand_path('../../../default_config/.kolorrc.rb', __dir__)
      end

      # Returns the path to the first existing config file.
      #
      # @return [String, nil] path to config file or nil if none found
      def config_file_path
        find_existing_config_file
      end

      # Finds the first existing config file among supported formats.
      #
      # @return [String, nil] path to config file or nil
      def find_existing_config_file
        return CONFIG_FILE_RB if !CONFIG_FILE_RB.nil? && File.exist?(CONFIG_FILE_RB)
        return CONFIG_FILE_ALIAS if !CONFIG_FILE_ALIAS.nil? && File.exist?(CONFIG_FILE_ALIAS)

        nil
      end

      # Loads and executes a Ruby config file.
      # Ensures Kolor::Extra is loaded before execution.
      #
      # @param path [String] absolute path to config file
      # @return [void]
      def load_ruby_config(path)
        ensure_extra_loaded
        load path
      rescue SyntaxError, LoadError => e
        raise StandardError, e.message
      end

      # Ensures Kolor::Extra is loaded and included in String and ColorizedString.
      # This method is idempotent and safe to call multiple times.
      #
      # @return [void]
      def ensure_extra_loaded
        unless defined?(Kolor::Extra)
          require 'kolor/extra'
          return
        end

        String.include(Kolor::Extra) unless String.included_modules.include?(Kolor::Extra)

        if defined?(Kolor::ColorizedString)
          unless Kolor::ColorizedString.included_modules.include?(Kolor::Extra)
            Kolor::ColorizedString.include(Kolor::Extra)
          end
        end
      end
    end
  end
end
