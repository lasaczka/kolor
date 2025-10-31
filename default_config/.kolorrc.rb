# frozen_string_literal: true

# Kolor default configuration file
# This file is automatically created during gem installation

# Load extra features for custom themes and advanced functionality
# require 'kolor/extra'

# Configuration options
# Suppress warnings (e.g., when config file is not found)
# Kolor::Config.suppress_warnings = false

# Define custom themes
# Syntax: Kolor::Extra.theme(:theme_name, :foreground, :background, :style1, :style2, ...)

# Default themes
# # Define custom themes
# Kolor::Extra.theme(:success, :green, :bold)
# Kolor::Extra.theme(:error, :white, :on_red, :bold)
# Kolor::Extra.theme(:warning, :yellow, :bold)
# Kolor::Extra.theme(:info, :cyan)
# Kolor::Extra.theme(:debug, :magenta)
#
# # Custom themes
# Kolor::Extra.theme(:highlight, :black, :on_yellow)
# Kolor::Extra.theme(:alert, :yellow, :on_red, :bold, :underline)
# Kolor::Extra.theme(:tip, :blue, :bold)
# Kolor::Extra.theme(:note, :cyan, :underline)

# Conditional configuration
# Disable colors in CI environment
# Kolor.disable! if ENV['CI']

# Platform-specific themes
# if RUBY_PLATFORM.match?(/win32/)
#   Kolor::Extra.theme(:win_info, :blue, :bold)
# end