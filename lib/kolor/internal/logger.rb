# frozen_string_literal: true

require 'thread'

module Kolor
  # Kolor::Logger provides styled, leveled logging for terminal output.
  #
  # It supports five log levels: `:info`, `:warn`, `:error`, `:success`, and `:debug`.
  # Each level has a default ANSI style, which can be overridden per message.
  #
  # Logging behavior is controlled by environment variables:
  #   - `KOLOR_DEBUG` enables debug output
  #   - `KOLOR_VERBOSE` enables info output
  #
  # Warnings and errors are always shown unless suppressed via `suppress!`.
  #
  # @example Log a warning
  #   Kolor::Logger.warn("Something went wrong")
  #
  # @example Suppress warnings
  #   Kolor::Logger.suppress!
  module Logger
    DEBUG_ENV_KEY = :KOLOR_DEBUG
    INFO_ENV_KEY = :KOLOR_VERBOSE

    # Default ANSI styles for each log level
    #
    # @return [Hash{Symbol => Array<Symbol>}]
    DEFAULT_STYLES = {
      info:    [:cyan],
      warn:    [:yellow, :bold],
      error:   [:red, :bold],
      success: [:green],
      debug:   [:magenta]
    }.freeze

    # Display tags for each log level
    #
    # @return [Hash{Symbol => String}]
    LEVEL_TAGS = {
      info:    'INFO',
      warn:    'WARN',
      error:   'ERROR',
      success: 'OK',
      debug:   'DEBUG'
    }.freeze

    @suppress_warnings = false
    @mutex = Mutex.new

    class << self
      # Checks if debug output is enabled via ENV
      #
      # @return [Boolean]
      def show_debug? = !ENV[DEBUG_ENV_KEY.to_s].nil?

      # Checks if info output is enabled via ENV
      #
      # @return [Boolean]
      def show_info?  = !ENV[INFO_ENV_KEY.to_s].nil?

      # Logs an info-level message if verbose mode is enabled
      #
      # @param message [String]
      # @param styles [Array<Symbol>, nil]
      # @return [void]
      def info(message, styles = nil)
        log(:info, message, styles) if show_info?
      end

      # Logs a debug-level message if debug mode is enabled
      #
      # @param message [String]
      # @param styles [Array<Symbol>, nil]
      # @return [void]
      def debug(message, styles = nil)
        log(:debug, message, styles) if show_debug?
      end

      # Logs a warning message
      #
      # @param message [String]
      # @param styles [Array<Symbol>, nil]
      # @return [void]
      def warn(message, styles = nil)    log(:warn, message, styles)    end

      # Logs an error message
      #
      # @param message [String]
      # @param styles [Array<Symbol>, nil]
      # @return [void]
      def error(message, styles = nil)   log(:error, message, styles)   end

      # Logs a success message
      #
      # @param message [String]
      # @param styles [Array<Symbol>, nil]
      # @return [void]
      def success(message, styles = nil) log(:success, message, styles) end

      # Suppresses all warnings and errors
      #
      # @return [void]
      def suppress! = @suppress_warnings = true

      # Enables warnings and errors
      #
      # @return [void]
      def enable!   = @suppress_warnings = false

      # Checks if warnings are currently suppressed
      #
      # @return [Boolean]
      def suppress_warnings? = @suppress_warnings

      private

      # Internal log method used by all levels
      #
      # @param level [Symbol] log level
      # @param message [String]
      # @param styles [Array<Symbol>, nil]
      # @return [void]
      def log(level, message, styles)
        return if @suppress_warnings

        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        tag = LEVEL_TAGS[level] || level.to_s.upcase
        prefix = "[#{timestamp}] #{tag}: "

        full = prefix + message.to_s
        styled = apply_styles(full, styles || DEFAULT_STYLES[level])

        @mutex.synchronize { $stderr.puts(styled) }
      end

      # Applies ANSI styles to a message
      #
      # @param message [String]
      # @param styles [Array<Symbol>]
      # @return [String]
      def apply_styles(message, styles)
        return message unless styles && message.respond_to?(:dup)

        styles.reduce(message.dup) do |msg, style|
          msg.respond_to?(style) ? msg.public_send(style) : msg
        end
      end
    end
  end
end
