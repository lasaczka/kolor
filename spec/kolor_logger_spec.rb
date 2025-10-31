# frozen_string_literal: true

require 'spec_helper'
require 'kolor/internal/logger'

RSpec.describe Kolor::Logger do
  let(:message) { 'Test message' }

  before do
    Kolor::Logger.enable!
  end

  describe '.suppress!' do
    it 'suppresses warnings' do
      Kolor::Logger.suppress!
      expect(Kolor::Logger.suppress_warnings?).to be true
    end
  end

  describe '.enable!' do
    it 'enables warnings' do
      Kolor::Logger.suppress!
      Kolor::Logger.enable!
      expect(Kolor::Logger.suppress_warnings?).to be false
    end
  end

  describe 'log levels' do
    it 'logs info with default style' do
      expect { Kolor::Logger.info(message) }.to output(/INFO:.*#{message}/).to_stderr
    end

    it 'logs warn with default style' do
      expect { Kolor::Logger.warn(message) }.to output(/WARN:.*#{message}/).to_stderr
    end

    it 'logs error with default style' do
      expect { Kolor::Logger.error(message) }.to output(/ERROR:.*#{message}/).to_stderr
    end

    it 'logs success with default style' do
      expect { Kolor::Logger.success(message) }.to output(/OK:.*#{message}/).to_stderr
    end

    it 'logs debug with default style' do
      expect { Kolor::Logger.debug(message) }.to output(/DEBUG:.*#{message}/).to_stderr
    end
  end

  describe 'custom styles' do
    it 'applies custom styles to message' do
      expect { Kolor::Logger.info(message, [:red, :bold]) }.to output(/\e\[.*m.*#{message}/).to_stderr
    end
  end

  describe 'suppression behavior' do
    it 'does not output when suppressed' do
      Kolor::Logger.suppress!
      expect { Kolor::Logger.warn(message) }.not_to output.to_stderr
    end
  end
end
