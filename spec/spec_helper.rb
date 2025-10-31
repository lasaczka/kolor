# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'kolor'

ENV['KOLOR_DEBUG'] = '1'
ENV['KOLOR_VERBOSE'] = '1'

def cleanup_config_themes!
  config_keys = %i[
    priority_from_rb
    priority_from_alias
    test_custom
    test_alias_theme
    test_my_theme
  ]

  config_keys.each do |key|
    Kolor::Extra.remove_theme(key) if Kolor::Extra.theme_defined?(key)
  rescue ArgumentError
    # already removed
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    @original_verbose = $VERBOSE
    $VERBOSE = nil
  end

  config.before(:each) { cleanup_config_themes! }
  config.after(:each)  { cleanup_config_themes! }

  config.after(:suite) do
    $VERBOSE = @original_verbose
  end
end


