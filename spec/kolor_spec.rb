# frozen_string_literal: true

require 'spec_helper'
require 'kolor'
require 'kolor/internal/config'
require 'kolor/extra'
require 'kolor/internal/logger'
require 'tmpdir'
require 'fileutils'

RSpec.describe Kolor::Config do
  let(:temp_home) { Dir.mktmpdir('kolor_test') }
  let(:config_rb_path) { File.join(temp_home, '.kolorrc.rb') }
  let(:config_alias_path) { File.join(temp_home, '.kolorrc') }
  let(:config_json_path) { File.join(temp_home, '.kolorrc.json') }

  before do
    # Save original HOME
    @original_home = ENV['HOME']
    @original_userprofile = ENV['USERPROFILE']

    # Set temporary HOME
    ENV['HOME'] = temp_home
    ENV['USERPROFILE'] = temp_home

    # Reset logger state
    Kolor::Logger.enable!

    # Reload constants with new HOME path
    stub_const('Kolor::Config::HOME_PATH', temp_home)
    stub_const('Kolor::Config::CONFIG_FILE_RB', File.join(temp_home, '.kolorrc.rb'))
    stub_const('Kolor::Config::CONFIG_FILE_ALIAS', File.join(temp_home, '.kolorrc'))
  end

  after do
    # Restore original HOME
    ENV['HOME'] = @original_home
    ENV['USERPROFILE'] = @original_userprofile

    # Clean up temp directory
    FileUtils.rm_rf(temp_home) if Dir.exist?(temp_home)
  end

  describe '.config_exists?' do
    context 'when no config files exist' do
      it 'returns false' do
        expect(described_class.config_exists?).to be false
      end
    end

    context 'when .kolorrc.rb exists' do
      before { FileUtils.touch(config_rb_path) }

      it 'returns true' do
        expect(described_class.config_exists?).to be true
      end
    end

    context 'when .kolorrc exists' do
      before { FileUtils.touch(config_alias_path) }

      it 'returns true' do
        expect(described_class.config_exists?).to be true
      end
    end
  end

  describe '.create_default_config' do
    context 'when no config exists' do
      it 'creates .kolorrc.rb from default config' do
        expect(File.exist?(config_rb_path)).to be false

        described_class.create_default_config

        expect(File.exist?(config_rb_path)).to be true
      end

      it 'outputs a warning message' do
        expect(Kolor::Logger).to receive(:warn).with(/Created default configuration file/)
        described_class.create_default_config
      end

      it 'creates config with valid Ruby syntax' do
        described_class.create_default_config

        expect { load config_rb_path }.not_to raise_error
      end
    end

    context 'when .kolorrc.rb already exists' do
      before { FileUtils.touch(config_rb_path) }

      it 'does not overwrite existing config' do
        File.write(config_rb_path, '# Custom config')

        described_class.create_default_config

        expect(File.read(config_rb_path)).to eq('# Custom config')
      end

      it 'does not output warning' do
        expect(Kolor::Logger).not_to receive(:warn)
        described_class.create_default_config
      end
    end

    context 'when .kolorrc alias exists' do
      before { FileUtils.touch(config_alias_path) }

      it 'does not create .kolorrc.rb' do
        described_class.create_default_config

        expect(File.exist?(config_rb_path)).to be false
      end
    end

    context 'when HOME_PATH is nil' do
      before do
        stub_const('Kolor::Config::HOME_PATH', nil)
      end

      it 'outputs warning about missing home directory' do
        expect(Kolor::Logger).to receive(:warn).with('No home directory found')
        described_class.create_default_config
      end

      it 'does not raise an error' do
        expect { described_class.create_default_config }.not_to raise_error
      end
    end

    context 'when default config is not accessible' do
      before do
        allow(FileUtils).to receive(:cp).and_raise(StandardError.new('Permission denied'))
      end

      it 'outputs error message' do
        expect(Kolor::Logger).to receive(:warn).with(/Failed to create default config file/)
        described_class.create_default_config
      end

      it 'does not raise an error' do
        expect { described_class.create_default_config }.not_to raise_error
      end
    end
  end

  describe '.load_config' do
    context 'with Ruby config (.kolorrc.rb)' do
      let(:ruby_config_content) do
        <<~RUBY
          require 'kolor/extra'
          Kolor::Extra.theme(:test_custom, :red, :bold)
          Kolor::Logger.suppress!
        RUBY
      end

      before do
        File.write(config_rb_path, ruby_config_content)
      end

      it 'loads the Ruby config file' do
        described_class.load_config

        expect('Test'.respond_to?(:test_custom)).to be true
      end

      it 'executes DSL commands' do
        described_class.load_config

        described_class.load_config
        expect { Kolor::Logger.warn("should not appear") }.not_to output.to_stderr
      end

      it 'applies custom themes' do
        described_class.load_config

        described_class.load_config
        styled = 'Test'.public_send(:test_custom.to_s) rescue ''
        expect(styled.to_s).to match(/\e\[\d+(;\d+)*m/)
      end
    end

    context 'with Ruby config alias (.kolorrc)' do
      let(:ruby_config_content) do
        <<~RUBY
          require 'kolor/extra'
          Kolor::Extra.theme(:test_alias_theme, :blue, :underline)
        RUBY
      end

      before do
        File.write(config_alias_path, ruby_config_content)
      end

      it 'loads the .kolorrc file' do
        described_class.load_config

        expect('Test'.respond_to?(:test_alias_theme)).to be true
      end
    end

    context 'with invalid Ruby config' do
      before do
        File.write(config_rb_path, 'raise "Intentional error"')
      end

      it 'outputs error message' do
        expect(Kolor::Logger).to receive(:warn).with(/Error loading config file/)
        described_class.load_config
      end

      it 'does not raise an error' do
        expect { described_class.load_config }.not_to raise_error
      end
    end

    context 'when no config file exists' do
      it 'does not raise an error' do
        expect { described_class.load_config }.not_to raise_error
      end

      it 'does not output warnings' do
        expect(Kolor::Logger).not_to receive(:warn)
        described_class.load_config
      end
    end
  end

  describe '.init' do
    context 'when no config exists' do
      it 'creates default config' do
        expect(File.exist?(config_rb_path)).to be false

        described_class.init

        expect(File.exist?(config_rb_path)).to be true
      end

      it 'loads the created config' do
        described_class.init

        # Default config should include standard themes
        expect('Test'.respond_to?(:success)).to be true
        expect('Test'.respond_to?(:error)).to be true
        expect('Test'.respond_to?(:warning)).to be true
      end
    end

    context 'when config already exists' do
      let(:custom_config) do
        <<~RUBY
          require 'kolor/extra'
          Kolor::Extra.theme(:test_my_theme, :cyan, :bold)
        RUBY
      end

      before do
        File.write(config_rb_path, custom_config)
      end

      it 'does not overwrite existing config' do
        described_class.init

        expect(File.read(config_rb_path)).to eq(custom_config)
      end

      it 'loads the existing config' do
        described_class.init

        expect('Test'.respond_to?(:test_my_theme)).to be true
      end
    end
  end

  describe 'integration with Kolor::Logger' do
    context 'when warnings are suppressed' do
      before do
        Kolor::Logger.suppress!
      end

      it 'does not output config creation message' do
        expect { described_class.create_default_config }.not_to output.to_stderr
      end
    end

    context 'when warnings are enabled' do
      before do
        allow(Kolor::Logger).to receive(:warn).and_call_original
      end

      it 'outputs config creation message' do
        described_class.create_default_config
        expect(Kolor::Logger).to have_received(:warn).with(/Created default configuration file/)
      end
    end
  end

  describe 'default config content' do
    before do
      described_class.create_default_config
    end

    it 'includes require for kolor/extra' do
      content = File.read(config_rb_path)
      expect(content).to include("require 'kolor/extra'")
    end

    it 'includes default themes' do
      content = File.read(config_rb_path)
      expect(content).to include('Kolor::Extra.theme(:success')
      expect(content).to include('Kolor::Extra.theme(:error')
      expect(content).to include('Kolor::Extra.theme(:warning')
    end

    it 'includes suppress_warnings example' do
      content = File.read(config_rb_path)
      expect(content).to include('suppress_warnings')
    end

    it 'includes conditional configuration examples' do
      content = File.read(config_rb_path)
      expect(content).to include("ENV['CI']")
    end
  end
end