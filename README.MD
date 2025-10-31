# Kolor

[![Gem Version](https://badge.fury.io/rb/kolor.svg)](https://badge.fury.io/rb/kolor)
[![Documentation](https://img.shields.io/badge/docs-rubydoc-blue.svg)](https://rubydoc.info/gems/kolor)
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](./LICENSE)
[![Coverage Status](https://coveralls.io/repos/github/lasaczka/kolor/badge.svg?branch=main)](https://coveralls.io/github/lasaczka/kolor?branch=main)
[![Ruby](https://img.shields.io/badge/ruby-3.0+-red.svg)](https://www.ruby-lang.org/en/)


Modern Ruby library for terminal text styling using ANSI escape codes with CLI support.

## Installation

Add to your Gemfile:

```ruby
gem 'kolor'
```

Or install directly:

```shell
gem install kolor
```

## Library Usage

```ruby
require 'kolor'

# Foreground colors
puts "Red text".red
puts "Green text".green
puts "Blue text".blue

# Background colors
puts "Text on red".on_red
puts "Text on blue".on_blue

# Styles
puts "Bold text".bold
puts "Underlined text".underline

# Chaining
puts "Red text on white background".red.on_white
puts "Bold green text".green.bold
puts "Complex styling".red.on_blue.bold.underline
```

## CLI Usage

### Basic Colors

```shell
kolor --red "Error message"
kolor --green "Success!"
kolor --yellow "Warning"
kolor --on-red "Alert"
kolor --white --on-blue "Information"
kolor --bold "Important"
kolor --underline "Emphasized"
kolor --bold --red "Critical"
kolor --red --on-white --bold "Error!"
```

### Themes (requires kolor/extra)

```shell
kolor --success "Operation completed"
kolor --error "Operation failed"
kolor --warning "Be careful"
kolor --info "FYI"
kolor --debug "Debugging info"
```

### Advanced Features

```shell
kolor --rgb 255,0,0 "Custom red"
kolor --with_hex FF5733 "Hex color"
kolor --gradient red,blue "Gradient text"
kolor --rainbow "Rainbow text"
```

### Utility Commands

```shell
kolor --list-colors
kolor --list-styles
kolor --list-themes
kolor --demo
kolor --version
kolor --help
```

## Available Colors

**Foreground:** `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`  
**Background:** `on_black`, `on_red`, `on_green`, `on_yellow`, `on_blue`, `on_magenta`, `on_cyan`, `on_white`  
**Styles:** `bold`, `underline`, `reversed`

## Advanced Features

Require extra features:

```ruby
require 'kolor'
require 'kolor/extra'
```

### 256 Colors

```ruby
"Text in color 196".color(196)
"Background color 20".on_color(20)
```

### RGB / True Color

```ruby
"RGB color".rgb(255, 100, 50)
"RGB background".on_rgb(0, 100, 200)
```

### Hex Colors

```ruby
"Hex color".with_hex("#FF5733")
"Hex background".on_hex("00BFFF")
```

### Gradients

```ruby
"Gradient text".gradient(:red, :blue)
"Rainbow colors".rainbow
```

### Themes

Built-in themes:

```ruby
"Success!".success    # green + bold
"Error!".error        # white on red + bold
"Warning!".warning    # yellow + bold
"Info".info           # cyan
"Debug".debug         # magenta
```

Custom themes:

```ruby
Kolor::Extra.theme(:custom, :red, :on_white, :bold)
"Custom styled".custom
```

## Utilities

### Disable Colors

```shell
kolor --no-color "Plain text"
```

```ruby
Kolor.disable!
"Text".red  # => "Text" (no ANSI codes)

Kolor.enable!
"Text".red  # => colored text
```

### Strip ANSI Codes

```ruby
colored = "Text".red.bold
Kolor.strip(colored)  # => "Text"
colored.uncolorize    # => "Text"
```

## CLI Examples

```shell
kolor --green "+ Added line"
kolor --red "- Removed line"
kolor --success "✓ Build passed"
kolor --error "✗ Build failed"
kolor --warning "⚠ Deprecated"
kolor --cyan "[INFO]" "Application started"
kolor --yellow "[WARN]" "Low memory"
kolor --red --bold "[ERROR]" "Connection failed"
kolor --rainbow "Celebrate!"
kolor --gradient red,yellow "Sunset vibes"
```

## Configuration File

Kolor supports a single configuration format:

### Ruby DSL (`~/.kolorrc.rb`)

```ruby
# Load extra features
require 'kolor/extra'

# Define custom themes
Kolor::Extra.theme(:success, :green, :bold)
Kolor::Extra.theme(:error, :white, :on_red, :bold)
Kolor::Extra.theme(:warning, :yellow, :bold)
Kolor::Extra.theme(:highlight, :black, :on_yellow)
Kolor::Extra.theme(:alert, :yellow, :on_red, :bold, :underline)

# Conditional configuration
Kolor.disable! if ENV['CI']

# Platform-specific themes
if RUBY_PLATFORM.match?(/win32/)
  Kolor::Extra.theme(:win_info, :blue, :bold)
end
```

### Use custom themes from config

```shell
kolor --highlight "Important!"
kolor --alert "Warning!"
```

```ruby
require 'kolor'
require 'kolor/extra'
require 'kolor/config'

Kolor::Config.init

puts "Success!".success
puts "Error!".error
```

## Environment Variables

- `NO_COLOR` or `NO_COLORS`: Disable colors automatically
- `KOLOR_FORCE`: Force colors even when output is redirected to a file

## Redirection Support

```shell
kolor --red "Error" > log.txt
KOLOR_FORCE=1 kolor --red "Error" > log.txt
echo "Hello World" | kolor --red --bold
cat file.txt | grep "error" | kolor --red
```

## Requirements

- Ruby >= 3.0.0
- Windows: Automatically loads `win32/console/ansi` if available

## Development

```shell
bundle exec rspec
```

## License

[BSD-3-Clause-Attribution](LICENSE)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request
