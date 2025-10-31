# frozen_string_literal: true

require_relative 'lib/kolor/internal/version'

Gem::Specification.new do |spec|
  spec.name          = 'kolor'
  spec.version       = Kolor::VERSION
  spec.authors       = ['Łasačka']
  spec.email         = ['saikinmirai@gmail.com']

  spec.summary       = 'Modern terminal text styling with ANSI codes'
  spec.description   = 'Ruby library for terminal text styling using ANSI escape codes. ' \
    'Supports basic colors, 256-color palette, RGB/true colors, gradients, themes, and CLI.'
  spec.homepage      = 'https://github.com/lasaczka/kolor'
  spec.license       = 'BSD-3-Clause-Attribution'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/kolor/#{spec.version}"
  spec.metadata['kolor:extra_status'] = 'experimental'

  spec.files = Dir[
    'lib/**/*',
    'bin/*',
    'default_config/**/*',
    'README.md',
    'LICENSE',
    'CHANGELOG.md'
  ]
  spec.bindir = 'bin'
  spec.executables = ['kolor']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
end