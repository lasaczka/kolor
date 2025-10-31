# frozen_string_literal: true

# Kolor::Enum::Foreground defines ANSI foreground color codes.
# Each entry maps a symbolic name to its corresponding ANSI value.
class Kolor::Enum::Foreground < Kolor::Enum
  type Integer

  # @return [Kolor::Enum::Foreground] black foreground (ANSI 30)
  entry :black,   30

  # @return [Kolor::Enum::Foreground] red foreground (ANSI 31)
  entry :red,     31

  # @return [Kolor::Enum::Foreground] green foreground (ANSI 32)
  entry :green,   32

  # @return [Kolor::Enum::Foreground] yellow foreground (ANSI 33)
  entry :yellow,  33

  # @return [Kolor::Enum::Foreground] blue foreground (ANSI 34)
  entry :blue,    34

  # @return [Kolor::Enum::Foreground] magenta foreground (ANSI 35)
  entry :magenta, 35

  # @return [Kolor::Enum::Foreground] cyan foreground (ANSI 36)
  entry :cyan,    36

  # @return [Kolor::Enum::Foreground] white foreground (ANSI 37)
  entry :white,   37
end
