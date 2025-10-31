# frozen_string_literal: true

# Kolor::Enum::Theme defines named color themes for terminal output.
# Each theme is a structured hash containing:
#   - foreground: the main text color
#   - background: optional background color
#   - styles: optional array of text styles (e.g. :bold, :underline)
#
# These themes are used to apply consistent formatting across messages,
# and can be extended or overridden via Kolor::Extra.theme.
#
# @example
#   Kolor::Enum::Theme[:success].value
#   # => { foreground: :green, background: nil, styles: [:bold] }
class Kolor::Enum::Theme < Kolor::Enum
  type Hash

  # @return [Kolor::Enum::Theme] green bold text for success messages
  entry :success, { foreground: :green, background: nil, styles: [:bold] }

  # @return [Kolor::Enum::Theme] white text on red background for errors
  entry :error,   { foreground: :white, background: :red, styles: [:bold] }

  # @return [Kolor::Enum::Theme] yellow bold text for warnings
  entry :warning, { foreground: :yellow, background: nil, styles: [:bold] }

  # @return [Kolor::Enum::Theme] cyan text for informational messages
  entry :info,    { foreground: :cyan, background: nil, styles: [] }

  # @return [Kolor::Enum::Theme] magenta text for debugging output
  entry :debug,   { foreground: :magenta, background: nil, styles: [] }
end
