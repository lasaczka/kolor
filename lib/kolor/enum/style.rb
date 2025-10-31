# frozen_string_literal: true

# Kolor::Enum::Style defines ANSI text style codes.
# These control formatting like bold, underline, and reversed text.
class Kolor::Enum::Style < Kolor::Enum
  type Integer

  # @return [Kolor::Enum::Style] reset all styles (ANSI 0)
  entry :clear,     0

  # @return [Kolor::Enum::Style] bold text (ANSI 1)
  entry :bold,      1

  # @return [Kolor::Enum::Style] underlined text (ANSI 4)
  entry :underline, 4

  # @return [Kolor::Enum::Style] reversed foreground/background (ANSI 7)
  entry :reversed,  7
end
