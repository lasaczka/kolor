# frozen_string_literal: true

require_relative '../kolor'
require_relative 'internal/config'
require 'optparse'

module Kolor
  ##
  # Kolor::CLI provides a command-line interface for the Kolor library.
  #
  # It supports:
  # - Foreground and background colors
  # - Text styles (bold, underline, etc.)
  # - Predefined themes (via kolor/extra)
  # - RGB and hex color input
  # - Gradients and rainbow effects
  # - Utility commands like listing options or showing a demo
  #
  # Input can be passed as arguments or piped via stdin.
  # Output is automatically colorized unless redirected, in which case colors are disabled unless `KOLOR_FORCE` is set.
  #
  # @example Basic usage
  #   kolor --red "Hello"
  #
  # @example Piped input
  #   echo "Hello" | kolor --green --bold
  #
  # @example Theme usage (requires kolor/extra)
  #   kolor --success "Done!"
  #
  # @example List available styles
  #   kolor --list-styles
  #
  # @example Show demo
  #   kolor --demo
  class CLI
    ##
    # Initializes the CLI with given arguments.
    #
    # @param args [Array<String>] command-line arguments (defaults to ARGV)
    def initialize(args = ARGV)
      @args = args
      @options = {}
    end

    ##
    # Runs the CLI command.
    #
    # Loads config, parses options, and dispatches to appropriate handler.
    #
    # @return [void]
    def run
      Kolor::Config.init if extra_available?
      parse_options

      if @options[:list_colors]
        list_colors
      elsif @options[:list_styles]
        list_styles
      elsif @options[:list_themes]
        list_themes
      elsif @options[:demo]
        show_demo
      elsif @options[:version]
        puts "Kolor #{Kolor::VERSION}"
      elsif @options[:help]
        puts @option_parser
      else
        colorize_text
      end
    end

    private

    ##
    # Parses CLI options using OptionParser.
    #
    # Populates @options hash with parsed flags and values.
    #
    # @return [void]
    def parse_options
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: kolor [options] TEXT"
        opts.separator ""
        opts.separator "Examples:"
        opts.separator "  kolor --red 'Hello World'"
        opts.separator "  kolor --green --bold 'Success!'"
        opts.separator "  echo 'Hello' | kolor --red"
        opts.separator "  kolor --success 'Done!' (requires kolor/extra)"
        opts.separator ""
        opts.separator "Options:"

        Kolor::Enum::Foreground.keys.each do |color|
          opts.on("--#{color}", "Apply #{color} foreground") { @options[:foreground] = color }
        end

        Kolor::Enum::Background.keys.each do |color|
          opts.on("--on-#{color}", "Apply #{color} background") { @options[:background] = color }
        end

        Kolor::Enum::Style.keys.reject { |s| s == :clear }.each do |style|
          opts.on("--#{style}", "Apply #{style} style") do
            @options[:styles] ||= []
            @options[:styles] << style
          end
        end

        opts.on("--success", "Apply success theme (green + bold)") do
          @options[:theme] = :success
          require_extra
        end

        opts.on("--error", "Apply error theme (white on red + bold)") do
          @options[:theme] = :error
          require_extra
        end

        opts.on("--warning", "Apply warning theme (yellow + bold)") do
          @options[:theme] = :warning
          require_extra
        end

        opts.on("--info", "Apply info theme (cyan)") do
          @options[:theme] = :info
          require_extra
        end

        opts.on("--debug", "Apply debug theme (magenta)") do
          @options[:theme] = :debug
          require_extra
        end

        opts.on("--rgb R,G,B", Array, "Apply RGB color (e.g., 255,0,0)") do |rgb|
          require_extra
          @options[:rgb] = rgb.map(&:to_i)
        end

        opts.on("--with_hex COLOR", "Apply with_hex color (e.g., FF0000)") do |hex|
          require_extra
          @options[:with_hex] = hex
        end

        opts.on("--gradient START,END", Array, "Apply gradient (e.g., red,blue)") do |colors|
          require_extra
          @options[:gradient] = colors.map(&:to_sym)
        end

        opts.on("--rainbow", "Apply rainbow effect") do
          require_extra
          @options[:rainbow] = true
        end

        opts.on("--list-colors", "List available colors") { @options[:list_colors] = true }
        opts.on("--list-styles", "List available styles") { @options[:list_styles] = true }
        opts.on("--list-themes", "List available themes") { @options[:list_themes] = true }
        opts.on("--demo", "Show color demonstration") { @options[:demo] = true }
        opts.on("--no-color", "Disable colors") { Kolor.disable! }
        opts.on("-v", "--version", "Show version") { @options[:version] = true }
        opts.on("-h", "--help", "Show this help") { @options[:help] = true }
      end

      @option_parser.parse!(@args)
    end

    ##
    # Requires kolor/extra and exits with error if not available.
    #
    # @return [void]
    def require_extra
      require_relative 'extra'
    rescue LoadError
      puts "Error: kolor/extra is required for this feature"
      exit 1
    end

    ##
    # Checks if kolor/extra is available.
    #
    # @return [Boolean]
    def extra_available?
      require_relative 'extra'
      true
    rescue LoadError
      false
    end

    ##
    # Applies selected colors/styles/themes to input text and prints result.
    #
    # @return [void]
    def colorize_text
      text = if @args.empty?
               if $stdin.tty?
                 puts "Error: No text provided"
                 puts @option_parser
                 exit 1
               else
                 $stdin.read.chomp
               end
             else
               @args.join(' ')
             end

      Kolor.disable! if !$stdout.tty? && Kolor.enabled? && !ENV['KOLOR_FORCE']

      if @options[:gradient]
        text = text.gradient(*@options[:gradient])
      elsif @options[:rainbow]
        text = text.rainbow
      elsif @options[:theme]
        text = text.public_send(@options[:theme])
      else
        text = text.rgb(*@options[:rgb]) if @options[:rgb]&.size == 3
        text = text.with_hex(@options[:with_hex]) if @options[:with_hex]
        text = text.public_send(@options[:foreground]) if @options[:foreground]
        text = text.public_send("on_#{@options[:background]}") if @options[:background]
        @options[:styles]&.each { |style| text = text.public_send(style) }
      end

      puts text
    end

    ##
    # Lists available foreground colors.
    #
    # @return [void]
    def list_colors
      puts "Available colors:\n\n"
      Kolor::Enum::Foreground.keys.each do |color|
        puts "  #{color.to_s.ljust(10)} - " + "Sample text".public_send(color)
      end
    end

    ##
    # Lists available text styles.
    #
    # @return [void]
    def list_styles
      puts "Available styles:\n\n"
      Kolor::Enum::Style.keys.reject { |s| s == :clear }.each do |style|
        puts "  #{style.to_s.ljust(10)} - " + "Sample text".public_send(style)
      end
    end

    ##
    # Lists available themes (requires kolor/extra).
    #
    # @return [void]
    def list_themes
      require_extra
      puts "Available themes:\n\n"
      Kolor::Extra.themes.each do |theme|
        config = Kolor::Extra.get_theme(theme)
        description = []
        description << config[:foreground].to_s if config[:foreground]
        description << "on_#{config[:background]}" if config[:background]
        description += config[:styles].map(&:to_s)
        puts "  #{theme.to_s.ljust(10)} - " + "Sample text".public_send(theme) +
             " (#{description.join(', ')})"
      end
    end

    ##
    # Displays a full demo of colors, backgrounds, styles, and themes.
    #
    # @return [void]
    def show_demo
      puts "=== Kolor Demo ==="
      puts ""

      puts "Basic colors:"
      Kolor::Enum::Foreground.keys.each do |color|
        print "#{color}: ".ljust(12)
        puts "The quick brown fox".public_send(color)
      end
      puts ""

      puts "Background colors:"
      Kolor::Enum::Background.keys.each do |color|
        print "on_#{color}: ".ljust(12)
        puts "The quick brown fox".public_send("on_#{color}")
      end
      puts ""

      puts "Styles:"
      Kolor::Enum::Style.keys.reject { |s| s == :clear }.each do |style|
        print "#{style}: ".ljust(12)
        puts "The quick brown fox".public_send(style)
      end
      puts ""

      puts "Combinations:"
      puts "Red on white: " + "The quick brown fox".red.on_white
      puts "Bold green:   " + "The quick brown fox".green.bold
      puts "Complex:      " + "The quick brown fox".red.on_blue.bold.underline
      puts ""

      if extra_available?
        puts "Themes:"
        Kolor::Extra.themes.each do |theme|
          puts "#{theme}: ".ljust(12) + "The quick brown fox".public_send(theme)
        end
        puts ""

        puts "Rainbow:"
        puts "The quick brown fox jumps over the lazy dog".rainbow
      end
    end
  end
end
