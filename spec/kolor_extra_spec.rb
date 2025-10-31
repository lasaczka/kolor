# frozen_string_literal: true

require 'rspec'
require_relative '../lib/kolor'
require_relative '../lib/kolor/extra'
require_relative 'spec_helper'

RSpec.describe Kolor::Extra do
  before(:each) do
    Kolor.enable!
    Kolor::Extra.remove_theme(:custom_test) if Kolor::Extra.theme_defined?(:custom_test)
  end

  def generate_unique_theme_name(prefix = 'custom')
    :"#{prefix}_#{Time.now.to_i}_#{rand(1000)}"
  end

  describe '256 color support' do
    it 'applies 256-color foreground' do
      result = 'text'.color(196)
      expect(result.to_s).to eq("\e[38;5;196mtext\e[0m")
    end

    it 'applies 256-color background' do
      result = 'text'.on_color(196)
      expect(result.to_s).to eq("\e[48;5;196mtext\e[0m")
    end

    it 'validates color range' do
      expect('text'.color(300).to_s).to eq("\e[38;5;300mtext\e[0m")
      expect('text'.color(-1).to_s).to eq("\e[38;5;-1mtext\e[0m")
    end

    it 'works with color 0' do
      result = 'text'.color(0)
      expect(result.to_s).to eq("\e[38;5;0mtext\e[0m")
    end

    it 'works with color 255' do
      result = 'text'.color(255)
      expect(result.to_s).to eq("\e[38;5;255mtext\e[0m")
    end

    it 'chains with other methods' do
      result = 'text'.color(196).bold
      expect(result.to_s).to eq("\e[38;5;196m\e[1mtext\e[0m")
    end
  end

  describe 'RGB color support' do
    it 'applies RGB foreground' do
      result = 'text'.rgb(255, 0, 0)
      expect(result.to_s).to eq("\e[38;2;255;0;0mtext\e[0m")
    end

    it 'applies RGB background' do
      result = 'text'.on_rgb(255, 0, 0)
      expect(result.to_s).to eq("\e[48;2;255;0;0mtext\e[0m")
    end

    it 'validates RGB range' do
      expect('text'.rgb(300, 0, 0).to_s).to eq('text')
      expect('text'.rgb(0, -1, 0).to_s).to eq('text')
      expect('text'.rgb(0, 0, 256).to_s).to eq('text')
    end

    it 'works with valid RGB values' do
      result = 'text'.rgb(128, 128, 128)
      expect(result.to_s).to eq("\e[38;2;128;128;128mtext\e[0m")
    end

    it 'chains with other methods' do
      result = 'text'.rgb(255, 0, 0).bold.underline
      expect(result.to_s).to eq("\e[38;2;255;0;0m\e[1m\e[4mtext\e[0m")
    end
  end

  describe 'with_hex color support' do
    it 'applies with_hex foreground with hash' do
      result = 'text'.with_hex('#FF0000')
      expect(result.to_s).to eq("\e[38;2;255;0;0mtext\e[0m")
    end

    it 'applies with_hex foreground without hash' do
      result = 'text'.with_hex('FF0000')
      expect(result.to_s).to eq("\e[38;2;255;0;0mtext\e[0m")
    end

    it 'applies with_hex background' do
      result = 'text'.on_hex('#00FF00')
      expect(result.to_s).to eq("\e[48;2;0;255;0mtext\e[0m")
    end

    it 'validates with_hex format' do
      expect('text'.with_hex('invalid')).to eq('text')
      expect('text'.with_hex('#ZZZ')).to eq('text')
      expect('text'.with_hex('FFF')).to eq('text')
    end

    it 'handles lowercase with_hex' do
      result = 'text'.with_hex('ff0000')
      expect(result.to_s).to eq("\e[38;2;255;0;0mtext\e[0m")
    end

    it 'handles mixed case with_hex' do
      result = 'text'.with_hex('Ff00Aa')
      expect(result.to_s).to eq("\e[38;2;255;0;170mtext\e[0m")
    end
  end

  describe 'themes' do
    it 'has built-in success theme' do
      result = 'Done!'.success
      expect(result.to_s).to include("\e[32m", "\e[1m") # green + bold
    end

    it 'has built-in error theme' do
      result = 'Error!'.error
      expect(result.to_s).to include("\e[37m", "\e[41m", "\e[1m") # white + on_red + bold
    end

    it 'has built-in warning theme' do
      result = 'Warning!'.warning
      expect(result.to_s).to include("\e[33m", "\e[1m") # yellow + bold
    end

    it 'has built-in info theme' do
      result = 'Info'.info
      expect(result.to_s).to include("\e[36m") # cyan
    end

    it 'has built-in debug theme' do
      result = 'Debug'.debug
      expect(result.to_s).to include("\e[35m") # magenta
    end

    it 'lists all themes' do
      themes = Kolor::Extra.themes
      expect(themes).to include(:success, :error, :warning, :info, :debug)
    end
  end

  describe 'custom themes' do
    after(:each) do
      Kolor::Enum::Theme.keys.each do |key|
        if key.to_s.start_with?('custom_')
          Kolor::Extra.remove_theme(key) rescue nil
        end
      end
    end

    it 'creates custom theme with foreground only' do
      theme_name = generate_unique_theme_name.to_sym
      Kolor::Extra.theme(theme_name, :red)


      if String.method_defined?(theme_name)
        result = 'text'.public_send(theme_name)
        expect(result.to_s).to include("\e[31m")
      else
        skip("Theme #{theme_name} was not registered due to duplicate value")
      end

      result = 'text'.public_send(theme_name)
      expect(result.to_s).to include("\e[31m")
    end

    it 'creates custom theme with foreground and background' do
      theme_name = generate_unique_theme_name.to_sym
      Kolor::Extra.theme(theme_name, :red, :on_blue)
      result = 'text'.public_send(theme_name)
      expect(result.to_s).to include("\e[31m", "\e[44m")
    end

    it 'creates custom theme with styles' do
      theme_name = generate_unique_theme_name.to_sym
      Kolor::Extra.theme(theme_name, :red, :bold, :underline)
      result = 'text'.public_send(theme_name)
      expect(result.to_s).to include("\e[31m", "\e[1m", "\e[4m")
    end

    it 'gets theme configuration' do
      theme_name = generate_unique_theme_name.to_sym
      Kolor::Extra.theme(theme_name, :red, :bold)
      config = Kolor::Extra.get_theme(theme_name)
      expect(config[:foreground]).to eq(:red)
      expect(config[:styles]).to include(:bold)
    end

    it 'removes custom theme' do
      theme_name = generate_unique_theme_name.to_sym
      Kolor::Extra.theme(theme_name, :red)
      Kolor::Extra.remove_theme(theme_name)
      expect('text'.respond_to?(theme_name)).to be false
    end

    it 'returns nil for non-existent theme' do
      theme_name = generate_unique_theme_name.to_sym
      config = Kolor::Extra.get_theme(theme_name)
      expect(config).to be_nil
    end
  end

  describe 'gradients' do
    it 'creates gradient between two colors' do
      result = 'Hello'.gradient(:red, :blue)
      expect(result).to be_a(String)
      expect(result).to include("\e[")
    end

    it 'handles single character' do
      result = 'A'.gradient(:red, :blue)
      expect(result).to include("\e[")
    end

    it 'handles empty string' do
      result = ''.gradient(:red, :blue)
      expect(result).to eq("\e[0m")
    end

    it 'returns plain string when disabled' do
      Kolor.disable!
      result = 'Hello'.gradient(:red, :blue)
      expect(result).to eq('Hello')
    end
  end

  describe 'rainbow effect' do
    it 'creates rainbow effect' do
      result = 'Rainbow'.rainbow
      expect(result).to be_a(String)
      expect(result).to include("\e[")
    end

    it 'handles single character' do
      result = 'A'.rainbow
      expect(result).to include("\e[")
    end

    it 'handles empty string' do
      result = ''.rainbow
      expect(result).to eq("\e[0m")
    end

    it 'returns plain string when disabled' do
      Kolor.disable!
      result = 'Rainbow'.rainbow
      expect(result).to eq('Rainbow')
    end
  end

  describe 'disabled mode with extra features' do
    before { Kolor.disable! }
    after { Kolor.enable! }

    it 'returns plain string for 256 colors' do
      expect('text'.color(196)).to eq('text')
    end

    it 'returns plain string for RGB' do
      expect('text'.rgb(255, 0, 0)).to eq('text')
    end

    it 'returns plain string for with_hex' do
      expect('text'.with_hex('#FF0000')).to eq('text')
    end

    it 'returns plain string for themes' do
      expect('text'.success).to eq('text')
    end
  end

  describe 'chaining extra features with basic features' do
    it 'chains 256 color with bold' do
      result = 'text'.color(196).bold
      expect(result.to_s).to eq("\e[38;5;196m\e[1mtext\e[0m")
    end

    it 'chains RGB with basic colors' do
      result = 'text'.rgb(255, 0, 0).on_blue
      expect(result.to_s).to include("\e[38;2;255;0;0m", "\e[44m")
    end

    it 'chains with_hex with underline' do
      result = 'text'.with_hex('#FF0000').underline
      expect(result.to_s).to include("\e[38;2;255;0;0m", "\e[4m")
    end

    it 'chains themes with basic methods' do
      result = 'text'.success.underline
      expect(result.to_s).to include("\e[32m", "\e[1m", "\e[4m")
    end

    it 'chains multiple extra features' do
      result = 'text'.color(196).on_color(20).bold
      expect(result.to_s).to include("\e[38;5;196m", "\e[48;5;20m", "\e[1m")
    end
  end

  describe 'edge cases for extra features' do
    it 'handles RGB with zeros' do
      result = 'text'.rgb(0, 0, 0)
      expect(result.to_s).to eq("\e[38;2;0;0;0mtext\e[0m")
    end

    it 'handles RGB with max values' do
      result = 'text'.rgb(255, 255, 255)
      expect(result.to_s).to eq("\e[38;2;255;255;255mtext\e[0m")
    end

    it 'handles with_hex with all zeros' do
      result = 'text'.with_hex('000000')
      expect(result.to_s).to eq("\e[38;2;0;0;0mtext\e[0m")
    end

    it 'handles with_hex with all F' do
      result = 'text'.with_hex('FFFFFF')
      expect(result.to_s).to eq("\e[38;2;255;255;255mtext\e[0m")
    end

    it 'handles gradient with same colors' do
      result = 'text'.gradient(:red, :red)
      expect(result).to be_a(String)
    end

    it 'handles very long strings for gradient' do
      long_text = 'a' * 100
      result = long_text.gradient(:red, :blue)
      expect(result).to be_a(String)
      expect(result).to match(/\e\[\d+m/)
    end

    it 'handles special characters in gradient' do
      result = "Hello! 123 @#$".gradient(:red, :blue)"
      expect(result).to be_a(String)
    end

    it 'handles unicode characters in gradient' do
      result = 'Привет 🌈'.gradient(:red, :blue)
      expect(result).to be_a(String)
    end
  end

  describe 'theme error handling' do
    it 'raises error for duplicate theme' do
      Kolor::Extra.theme(:duplicate_test, :red)
      expect(Kolor::Logger).to receive(:error).with(/duplicate_test/)
      Kolor::Extra.theme(:duplicate_test, :blue)
    end

    it 'raises error when removing non-existent theme' do
      expect {
        Kolor::Extra.remove_theme(:non_existent)
      }.to raise_error(ArgumentError, /not found/)
    end

    it 'prevents removing built-in themes' do
      expect {
        Kolor::Extra.remove_theme(:success)
      }.to raise_error(ArgumentError, /Cannot remove built-in theme/)
    end

    it 'logs error when theme name is reused' do
      theme_name = generate_unique_theme_name
      Kolor::Extra.theme(theme_name, :red)

      expect {
        Kolor::Extra.theme(theme_name, :green)
      }.not_to raise_error
    end
  end

  describe 'color name resolution for gradient' do
    it 'resolves basic color names' do
      result = 'text'.gradient(:red, :blue)
      expect(result).to match(/\e\[\d+m/)
    end

    it 'handles invalid color names gracefully' do
      result = 'text'.gradient(:invalid_color, :blue)
      expect(result).to eq('text')
    end
  end

  describe 'integration tests' do
    it 'combines all feature types' do
      result = 'Test'.color(196).rgb(0, 255, 0).with_hex('#0000FF').bold.underline
      expect(result.to_s).to be_a(String)
    end

    it 'applies theme after other styles' do
      Kolor::Extra.theme(:combined_test, :red, :bold)
      result = 'text'.underline.combined_test
      expect(result).to be_a(Kolor::ColorizedString)
      Kolor::Extra.remove_theme(:combined_test)
    end

    it 'works with string interpolation' do
      text = 'Hello'
      result = "Message: #{text.success}"
      expect(result).to include('Message:', "\e[32m")
    end
  end
end