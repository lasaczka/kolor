# frozen_string_literal: true

require 'rspec'
require_relative '../lib/kolor/cli'

RSpec.describe Kolor::CLI do
  let(:cli) { described_class.new(args) }

  before(:each) do
    ENV['KOLOR_FORCE'] = '1'
    Kolor.enable!
  end

  describe 'basic color options' do
    context 'with foreground colors' do
      let(:args) { %w[--red Hello] }

      it 'applies red color' do
        output = capture_stdout { cli.run }
        expect(output).to include("\e[31m")
        expect(output).to include("Hello")
      end
    end

    context 'with background colors' do
      let(:args) { %w[--on-blue Hello] }

      it 'applies blue background' do
        expect { cli.run }.to output(/\e\[44mHello\e\[0m/).to_stdout
      end
    end

    context 'with multiple words' do
      let(:args) { %w[--green Hello World] }

      it 'joins text with spaces' do
        expect { cli.run }.to output(/Hello World/).to_stdout
      end
    end
  end

  describe 'style options' do
    context 'with bold' do
      let(:args) { %w[--bold Text] }

      it 'applies bold style' do
        expect { cli.run }.to output(/\e\[1mText\e\[0m/).to_stdout
      end
    end

    context 'with underline' do
      let(:args) { %w[--underline Text] }

      it 'applies underline style' do
        expect { cli.run }.to output(/\e\[4mText\e\[0m/).to_stdout
      end
    end

    context 'with multiple styles' do
      let(:args) { %w[--bold --underline Text] }

      it 'applies multiple styles' do
        expect { cli.run }.to output(/\e\[1m.*\e\[4m/).to_stdout
      end
    end
  end

  describe 'combined options' do
    context 'with color and style' do
      let(:args) { %w[--red --bold Error] }

      it 'applies both color and style' do
        expect { cli.run }.to output(/\e\[31m.*\e\[1m/).to_stdout
      end
    end

    context 'with foreground and background' do
      let(:args) { %w[--red --on-white Alert] }

      it 'applies both foreground and background' do
        expect { cli.run }.to output(/\e\[31m.*\e\[47m/).to_stdout
      end
    end

    context 'with all options' do
      let(:args) { %w[--red --on-white --bold --underline Text] }

      it 'applies all formatting' do
        output = capture_stdout { cli.run }
        expect(output).to include("\e[31m")
        expect(output).to include("\e[47m")
        expect(output).to include("\e[1m")
        expect(output).to include("\e[4m")
      end
    end
  end

  describe 'utility commands' do
    context '--version' do
      let(:args) { ['--version'] }

      it 'displays version' do
        expect { cli.run }.to output(/Kolor #{Kolor::VERSION}/).to_stdout
      end
    end

    context '--help' do
      let(:args) { ['--help'] }

      it 'displays help message' do
        expect { cli.run }.to output(/Usage: kolor/).to_stdout
      end
    end

    context '--list-colors' do
      let(:args) { ['--list-colors'] }

      it 'lists all colors' do
        output = capture_stdout { cli.run }
        expect(output).to include('Available colors:')
        expect(output).to include('black')
        expect(output).to include('red')
        expect(output).to include('green')
      end
    end

    context '--list-styles' do
      let(:args) { ['--list-styles'] }

      it 'lists all styles' do
        output = capture_stdout { cli.run }
        expect(output).to include('Available styles:')
        expect(output).to include('bold')
        expect(output).to include('underline')
      end
    end

    context '--demo' do
      let(:args) { ['--demo'] }

      it 'shows demo output' do
        output = capture_stdout { cli.run }
        expect(output).to include('Kolor Demo')
        expect(output).to include('Basic colors:')
        expect(output).to include('Background colors:')
        expect(output).to include('Styles:')
      end
    end
  end

  describe '--no-color option' do
    let(:args) { %w[--no-color --red Plain] }

    it 'disables colors' do
      expect { cli.run }.to output("Plain\n").to_stdout
    end

    it 'sets Kolor.enabled? to false' do
      capture_stdout { cli.run }
      expect(Kolor.enabled?).to be false
    end
  end

  describe 'error handling' do
    context 'with no arguments' do
      let(:args) { [] }

      it 'shows error and exits' do
        expect { cli.run }.to raise_error(SystemExit)
                                .and output(/Error: No text provided/).to_stdout
      end
    end

    context 'with no text after options' do
      let(:args) { ['--red'] }

      it 'shows error and exits' do
        expect { cli.run }.to raise_error(SystemExit)
                                .and output(/Error: No text provided/).to_stdout
      end
    end
  end

  describe 'extra features' do
    before do
      require_relative '../lib/kolor/extra'
    end

    context 'with theme option' do
      let(:args) { %w[--success Done] }

      it 'applies success theme' do
        output = capture_stdout { cli.run }
        expect(output).to include("\e[32m") # green
        expect(output).to include("\e[1m")  # bold
      end
    end

    context 'with --list-themes' do
      let(:args) { ['--list-themes'] }

      it 'lists all themes' do
        output = capture_stdout { cli.run }
        expect(output).to include('Available themes:')
        expect(output).to include('success')
        expect(output).to include('error')
        expect(output).to include('warning')
      end
    end

    context 'with RGB option' do
      let(:args) { %w[--rgb 255,0,0 Red] }

      it 'applies RGB color' do
        expect { cli.run }.to output(/\e\[38;2;255;0;0m/).to_stdout
      end
    end

    context 'with with_hex option' do
      let(:args) { %w[--with_hex FF0000 Red] }

      it 'applies with_hex color' do
        expect { cli.run }.to output(/\e\[38;2;255;0;0m/).to_stdout
      end
    end

    context 'with gradient option' do
      let(:args) { %w[--gradient red,blue Gradient] }

      it 'applies gradient' do
        output = capture_stdout { cli.run }
        expect(Kolor.strip(output).chomp).to eq('Gradient')
        expect(output).to match(/\e\[\d+m/)
      end
    end

    context 'with rainbow option' do
      let(:args) { %w[--rainbow Rainbow] }

      it 'applies rainbow effect' do
        output = capture_stdout { cli.run }
        expect(output).to match(/\e\[\d+m/)
        expect(Kolor.strip(output).chomp).to eq('Rainbow')
      end
    end
  end

  describe 'all color options' do
    Kolor::Enum::Foreground.keys.each do |color|
      context "with --#{color}" do
        let(:args) { ["--#{color}", 'Text'] }

        it "applies #{color} color" do
          output = capture_stdout { cli.run }
          expect(output).to include('Text')
          expect(output).to match(/\e\[\d+m/)
        end
      end
    end

    Kolor::Enum::Foreground.keys.each do |color|
      context "with --on-#{color}" do
        let(:args) { ["--on-#{color}", 'Text'] }

        it "applies on_#{color} background" do
          output = capture_stdout { cli.run }
          expect(output).to include('Text')
          expect(output).to match(/\e\[\d+m/)
        end
      end
    end
  end

  describe 'edge cases' do
    context 'with empty text' do
      let(:args) { ['--red', ''] }

      it 'outputs colored empty string' do
        expect { cli.run }.to output(/\e\[31m\e\[0m/).to_stdout
      end
    end

    context 'with special characters' do
      let(:args) { %w[--red test@#$%] }

      it 'handles special characters' do
        expect { cli.run }.to output(/test@#\$%/).to_stdout
      end
    end

    context 'with unicode' do
      let(:args) { %w[--red тест 🎨] }

      it 'handles unicode characters' do
        expect { cli.run }.to output(/тест 🎨/).to_stdout
      end
    end

    context 'with multiple same options' do
      let(:args) { %w[--red --red Text] }

      it 'applies color once' do
        expect { cli.run }.to output(/\e\[31mText\e\[0m/).to_stdout
      end
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end