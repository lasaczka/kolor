# frozen_string_literal: true
# @!parse
#   class String
#     include Kolor::Extra
#   end
require_relative '../kolor'
require_relative 'internal/enum'
require_relative 'internal/logger'
require_relative 'enum/foreground'
require_relative 'enum/theme'
# Kolor::Extra provides advanced terminal styling features.
#
# Features:
#   - 256 color palette
#   - RGB/True color support
#   - Color gradients
#   - Named themes
#
# @example 256 colors
#   "text".color(196)           # foreground
#   "text".on_color(196)        # background
#
# @example RGB colors
#   "text".rgb(255, 0, 0)       # foreground
#   "text".on_rgb(255, 0, 0)    # background
#
# @example Gradients
#   "Hello World".gradient(:red, :blue)
#   "Rainbow".rainbow
#
# @example Themes
#   Kolor::Extra.theme(:success, :green, :bold)
#   "Done!".success
module Kolor
  # Extended functionality for Kolor including RGB colors, gradients, and themes
  module Extra
    # 256-color palette support
    # @param code [Integer] color code (0-255)
    # @return [String, ColorizedString] colorized string
    def color(code)
      create_colorized_string("\e[38;5;#{code}m")
    end

    # 256-color background palette support
    # @param code [Integer] color code (0-255)
    # @return [String, ColorizedString] colorized string
    def on_color(code)
      create_colorized_string("\e[48;5;#{code}m")
    end

    # RGB / True color support (foreground)
    # @param red [Integer] red component (0-255)
    # @param green [Integer] green component (0-255)
    # @param blue [Integer] blue component (0-255)
    # @return [String, ColorizedString] colorized string
    def rgb(red, green, blue)
      return to_s unless Kolor.enabled?
      return to_s unless [red, green, blue].all? { |v| v.between?(0, 255) }
      create_colorized_string("\e[38;2;#{red};#{green};#{blue}m")
    end

    # RGB / True color support (background)
    # @param red [Integer] red component (0-255)
    # @param green [Integer] green component (0-255)
    # @param blue [Integer] blue component (0-255)
    # @return [String, ColorizedString] colorized string
    def on_rgb(red, green, blue)
      return to_s unless Kolor.enabled?
      return to_s unless [red, green, blue].all? { |v| v.between?(0, 255) }
      create_colorized_string("\e[48;2;#{red};#{green};#{blue}m")
    end

    # Hex color support (foreground)
    # @param hex_color [String] with_hex color code (with or without #)
    # @return [String, ColorizedString] colorized string
    def with_hex(hex_color)
      return to_s unless Kolor.enabled?

      hex_color = hex_color.delete('#')
      return to_s unless hex_color.match?(/^[0-9A-Fa-f]{6}$/)

      r = hex_color[0..1].to_i(16)
      g = hex_color[2..3].to_i(16)
      b = hex_color[4..5].to_i(16)
      rgb(r, g, b)
    end

    # Hex color support (background)
    # @param hex_color [String] with_hex color code (with or without #)
    # @return [String, ColorizedString] colorized string
    def on_hex(hex_color)
      return to_s unless Kolor.enabled?

      hex_color = hex_color.delete('#')
      return to_s unless hex_color.match?(/^[0-9A-Fa-f]{6}$/)

      r = hex_color[0..1].to_i(16)
      g = hex_color[2..3].to_i(16)
      b = hex_color[4..5].to_i(16)
      on_rgb(r, g, b)
    end

    # Gradient between two colors
    # @param start_color [Symbol] starting color name
    # @param end_color [Symbol] ending color name
    # @return [String] string with gradient effect
    def gradient(start_color, end_color)
      return to_s unless Kolor.enabled?

      start_enum = Kolor::Enum::Foreground[start_color]
      end_enum = Kolor::Enum::Foreground[end_color]

      return to_s unless start_enum && end_enum

      start_code = start_enum.value
      end_code = end_enum.value

      chars = to_s.chars
      return Kolor.clear_code if chars.empty?

      result = chars.map.with_index do |char, i|
        progress = chars.length > 1 ? i.to_f / (chars.length - 1) : 0
        color_code = start_code + ((end_code - start_code) * progress).round
        "\e[#{color_code}m#{char}"
      end

      result.join + Kolor.clear_code
    end

    # Rainbow colors
    # @return [String] string with rainbow effect
    def rainbow
      return to_s unless Kolor.enabled?

      colors = %i[red yellow green cyan blue magenta]
      chars = to_s.chars

      return Kolor.clear_code if chars.empty?

      result = chars.map.with_index do |char, i|
        color = colors[i % colors.length]
        enum = Kolor::Enum::Foreground[color]
        code = enum.value
        "\e[#{code}m#{char}"
      end

      result.join + Kolor.clear_code
    end

    # Define a custom theme
    # @param name [Symbol] theme name
    # @param styles [Array<Symbol>] list of color and style names to apply
    # @example
    #   Kolor::Extra.theme(:error, :white, :on_red, :bold)
    #   "Error!".error # => white text on red background, bold
    def self.theme(name, *styles)
      begin
        Kolor::Enum::Theme.entry(name, normalize_styles(styles))
        define_theme_method(name, styles)
      rescue ArgumentError => e
        if e.message =~ /already assigned to (\w+)/
          existing = Regexp.last_match(1)
          Kolor::Logger.warn("Theme value already registered as :#{existing}. Skipping :#{name}.")
        else
          Kolor::Logger.error("Theme registration failed for #{name}: #{e.message}")
        end
      rescue TypeError => e
        Kolor::Logger.error("Theme registration failed for #{name}: #{e.message}")
      end
    end



    # Defines a theme method on String and ColorizedString
    # @param name [Symbol] theme name
    # @param styles [Array<Symbol>] list of style methods to apply
    # @return [void]
    def self.define_theme_method(name, styles)
      # Define the method on both String and ColorizedString
      [String, Kolor::ColorizedString].each do |klass|
        klass.class_eval do
          # Remove existing method if present to avoid warnings
          remove_method(name) if method_defined?(name)

          # Define the theme method
          define_method(name) do
            # Return plain string if colors are disabled
            return to_s unless Kolor.enabled?

            # Apply each style in sequence
            result = self
            styles.each do |style|
              # Verify the style method exists before calling it
              if result.respond_to?(style)
                result = result.public_send(style)
              else
                # Log warning but continue with other styles
                Kolor::Logger.debug "Style '#{style}' not found for theme '#{name}'"
              end
            end

            result
          end
        end
      end

      Kolor::Logger.debug "Defined theme method '#{name}' with styles #{styles.inspect}"
    end

    # Normalizes a list of style symbols into a structured theme hash.
    # Extracts foreground, background, and remaining styles.
    #
    # @param styles [Array<Symbol>] list of style names (e.g., :green, :on_red, :bold)
    # @return [Hash{Symbol=>Symbol, Array<Symbol>}] normalized theme structure
    #   - :foreground → foreground color (Symbol or nil)
    #   - :background → background color (Symbol or nil)
    #   - :styles     → remaining style modifiers (Array<Symbol>)
    def self.normalize_styles(styles)
      fg = styles.find { |s| Kolor::Enum::Foreground.keys.include?(s) }
      bg = styles.find { |s| s.to_s.start_with?('on_') }
      rest = styles - [fg, bg].compact
      {
        foreground: fg,
        background: bg&.to_s&.sub(/^on_/, '')&.to_sym,
        styles: rest
      }
    end

    # Returns the list of all registered theme names.
    #
    # @return [Array<Symbol>] list of theme keys
    def self.themes
      Kolor::Enum::Theme.keys
    end

    # Retrieves the configuration object for a given theme.
    #
    # @param name [Symbol] theme name
    # @return [Object, nil] theme configuration or nil if not found or invalid
    #   Expected keys:
    #     - :foreground → foreground color (Symbol or nil)
    #     - :background → background color (Symbol or nil)
    #     - :styles     → style modifiers (Array<Symbol>)
    def self.get_theme(name)
      Kolor::Enum::Theme[name]&.value.then { |v| v.is_a?(Hash) ? v : nil }
    end

    def self.remove_theme(name)
      theme = Kolor::Enum::Theme[name]
      raise ArgumentError, "Theme #{name} not found" unless theme

      built_in = %i[success error warning info debug]
      raise ArgumentError, "Cannot remove built-in theme #{name}" if built_in.include?(name)

      Kolor::Logger.info("Removing theme #{name}")
      Kolor::Enum::Theme.remove(name)

      [String, Kolor::ColorizedString].each do |klass|
        klass.class_eval do
          remove_method(name) if method_defined?(name)
        end
      end
    end

    # Defines all built-in themes from Kolor::Enum::Theme
    # @return [void]
    def self.define_all_themes
      return if @themes_initialized
      Kolor::Logger.info('Built-in themes initialized') unless @themes_initialized
      @themes_initialized = true

      Kolor::Enum::Theme.keys.each do |name|
        config = Kolor::Enum::Theme[name].value
        next unless config.is_a?(Hash)

        styles = []
        styles << config[:foreground] if config[:foreground]
        styles << "on_#{config[:background]}".to_sym if config[:background]
        styles += config[:styles] if config[:styles].is_a?(Array)

        define_theme_method(name, styles)
      end
    end

    # Check if a theme method is defined
    # @param name [Symbol] theme name
    # @return [Boolean] true if the method exists on String
    def self.theme_defined?(name)
      String.method_defined?(name.to_sym)
    end

    # Init built-in themes
    self.define_all_themes
  end
end

# Extend String class with Extra methods
String.include(Kolor::Extra)
Kolor::ColorizedString.include(Kolor::Extra)

# Init built-in themes
Kolor::Extra.define_all_themes
