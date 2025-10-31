# frozen_string_literal: true
# @!parse
#   class String
#     include Kolor
#   end


# noinspection RubyResolve
require 'win32/console/ansi' if Gem.win_platform?
require_relative 'kolor/internal/version'
require_relative 'kolor/internal/enum'
require_relative 'kolor/enum/foreground'
require_relative 'kolor/enum/background'
require_relative 'kolor/enum/style'


# Kolor provides terminal text styling using ANSI escape codes.
#
# Available colors (foreground and background):
#   black, red, green, yellow, blue, magenta, cyan, white
#
# Available styles:
#   bold, underline, reversed
#
# @example Basic usage
#   "this is red".red
#   "this is red with a blue background".red.on_blue
#   "this is red with an underline".red.underline
#   "this is really bold and really blue".bold.blue
#
# @example Chaining styles
#   "complex styling".red.on_white.bold.underline
#
# @example All color methods
#   string.black / string.on_black
#   string.red / string.on_red
#   string.green / string.on_green
#   string.yellow / string.on_yellow
#   string.blue / string.on_blue
#   string.magenta / string.on_magenta
#   string.cyan / string.on_cyan
#   string.white / string.on_white
#
# @example Disabling colors (for CI/CD environments)
#   Kolor.disable!
#   "text".red # => "text" (no ANSI codes)
#   Kolor.enable!
#
# @example Stripping ANSI codes
#   Kolor.strip("text".red.bold) # => "text"
module Kolor
  # Regex to match ANSI escape codes
  ANSI_REGEX = /\e\[[\d;]*m/.freeze

  class << self
    # Check if colorization is enabled
    # @return [Boolean]
    attr_reader :enabled
    alias enabled? enabled

    # Returns list of available colors
    # @return [Array<Symbol>] sorted list of color names
    def colors
      @colors ||= Kolor::Enum::Foreground.keys.sort
    end

    # Enables colorization (default state)
    # @return [Boolean] true
    def enable!
      @enabled = true
    end

    # Disables colorization (useful for CI/CD, logging to files, etc.)
    # @return [Boolean] false
    def disable!
      @enabled = false
    end

    # Strips all ANSI escape codes from a string
    # @param string [String] string with ANSI codes
    # @return [String] clean string without ANSI codes
    def strip(string)
      result = string.to_s
      result.gsub(ANSI_REGEX, '')
    end

    # Generates ANSI escape code for a style enum
    # @param style_name [Symbol] symbolic name of the style (e.g. :bold, :underline)
    # @return [String] ANSI escape code (e.g. "\e[1m") or empty string if disabled or unknown
    def style_code(style_name)
      return '' unless @enabled

      style = Kolor::Enum::Style[style_name]
      style ? "\e[#{style.value}m" : ''
    end

    # Generates ANSI escape code for a foreground color
    # @param color_name [Symbol] name of the foreground color
    # @return [String] ANSI escape code or empty string if disabled or unknown
    def foreground_code(color_name)
      return '' unless @enabled

      color = Kolor::Enum::Foreground[color_name]
      color ? "\e[#{color.value}m" : ''
    end

    # Generates ANSI escape code for a background color
    # @param color_name [Symbol] name of the background color
    # @return [String] ANSI escape code or empty string if disabled or unknown
    def background_code(color_name)
      return '' unless @enabled

      color = Kolor::Enum::Background[color_name]
      color ? "\e[#{color.value}m" : ''
    end


    # Clears all ANSI formatting
    # @return [String] ANSI clear code or empty string if disabled
    def clear_code
      @enabled ? "\e[0m" : ''
    end
  end

  # Enable by default but disable if NO_COLOR env var is set
  @enabled = !ENV['NO_COLOR'] && !ENV['NO_COLORS']

  # Wrapper class to enable method chaining with ANSI codes
  class ColorizedString
    attr_reader :string, :codes

    def initialize(string, codes = [])
      @string = string
      @codes = codes
    end

    # Returns the fully colorized string
    # @return [String] string with all ANSI codes applied
    def to_s
      return @string unless Kolor.enabled?

      "#{@codes.join}#{@string}#{Kolor.clear_code}"
    end

    # Allow implicit string conversion
    alias to_str to_s

    # Clears all formatting and returns plain string
    # @return [String] plain string without ANSI codes
    def clear
      @string
    end

    # Adds a new ANSI code to the chain
    # @param code [String] ANSI escape code to add
    # @return [ColorizedString] new ColorizedString with the added code
    def add_code(code)
      return self unless Kolor.enabled? && code

      ColorizedString.new(@string, @codes + [code])
    end

    # Delegate string methods to the underlying string
    def method_missing(method_name, *args, &block)
      if @string.respond_to?(method_name)
        result = @string.public_send(method_name, *args, &block)
        result.is_a?(String) ? self.class.new(result, @codes) : result
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @string.respond_to?(method_name, include_private) || super
    end

    # Include Kolor module to get all color/style methods
    include Kolor

    private

    # Override to use add_code for ColorizedString
    def create_colorized_string(code)
      add_code(code)
    end
  end

  # Clears the line to the end (useful for dynamic terminal output)
  # @return [String] string with clear-to-end-of-line code
  def to_eol
    return to_s unless Kolor.enabled?

    str = to_s
    modified = str.sub(/^(\e\[[\d;]*m)/, "\\1\e[0K")
    modified == str ? "\e[0K#{str}" : modified
  end

  # Clears all ANSI formatting from the string
  # @return [String] plain string without ANSI codes
  def uncolorize
    Kolor.strip(to_s)
  end

  alias decolorize uncolorize

  private

  # Creates a ColorizedString with the given ANSI code
  # @param code [String] ANSI escape code to apply
  # @return [String, ColorizedString] colorized string or self if disabled
  def create_colorized_string(code)
    return to_s unless Kolor.enabled?

    if is_a?(ColorizedString)
      add_code(code)
    else
      ColorizedString.new(self, [code])
    end
  end

  public
  # Generate foreground color methods
  Kolor::Enum::Foreground.keys.each do |color|
    define_method(color) do
      create_colorized_string(Kolor.foreground_code(color))
    end
  end

  # Generate background color methods (on_*)
  Kolor::Enum::Background.keys.each do |color|
    define_method("on_#{color}") do
      create_colorized_string(Kolor.background_code(color))
    end
  end

  # Generate style methods
  Kolor::Enum::Style.keys.each do |style|
    next if style == :clear

    define_method(style) do
      create_colorized_string(Kolor.style_code(style))
    end
  end
end

# Extend String class with Kolor methods
String.include(Kolor)
