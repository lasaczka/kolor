# frozen_string_literal: true

# Kolor::Enum::Background defines ANSI background color codes.
# Each entry maps a symbolic name to its corresponding ANSI value.
class Kolor::Enum::Background < Kolor::Enum
  type Integer

  # @return [Kolor::Enum::Background] black background (ANSI 40)
  entry :black,   40

  # @return [Kolor::Enum::Background] red background (ANSI 41)
  entry :red,     41

  # @return [Kolor::Enum::Background] green background (ANSI 42)
  entry :green,   42

  # @return [Kolor::Enum::Background] yellow background (ANSI 43)
  entry :yellow,  43

  # @return [Kolor::Enum::Background] blue background (ANSI 44)
  entry :blue,    44

  # @return [Kolor::Enum::Background] magenta background (ANSI 45)
  entry :magenta, 45

  # @return [Kolor::Enum::Background] cyan background (ANSI 46)
  entry :cyan,    46

  # @return [Kolor::Enum::Background] white background (ANSI 47)
  entry :white,   47
end
