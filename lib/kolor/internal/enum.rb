# frozen_string_literal: true

# Kolor::Enum provides a declarative, type-safe registry for named values.
# Each entry is unique by both name and value. Values can be of any type,
# but you may optionally declare a type constraint using `type`.
#
# Enum entries are registered via `.entry(name, value)` and accessed via `.name` or `[]`.
# Each entry becomes a singleton method of the class and returns an instance of the enum.
#
# @example Define an enum
#   class MyEnum < Kolor::Enum
#     type Integer
#     entry :low, 1
#     entry :high, 2
#   end
#
# @example Access values
#   MyEnum[:low].value        # => 1
#   MyEnum.high.to_sym        # => :high
#   MyEnum.low == MyEnum[:low] # => true
module Kolor
  class Enum
    # @return [Object] the value associated with the enum entry
    attr_reader :value

    # Initializes a new enum instance with a given value
    #
    # @param value [Object] the raw value of the enum
    def initialize(value)
      @value = value
    end

    # Returns the symbolic name of the value as a string
    #
    # @return [String]
    def to_s     = self.class.name_for(value).to_s

    # Returns the symbolic name of the value as a symbol
    #
    # @return [Symbol]
    def to_sym   = self.class.name_for(value)

    # Returns a debug-friendly string representation
    #
    # @return [String]
    def inspect  = "#<#{self.class.name} #{to_sym.inspect}:#{value.inspect}>"

    # Equality based on class and value
    #
    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) && other.value == value
    end

    # Alias for `==`
    #
    # @param other [Object]
    # @return [Boolean]
    alias eql? ==

    # Hash code based on value
    #
    # @return [Integer]
    def hash = value.hash

    class << self
      # Declares the expected type of all enum values
      #
      # @param klass [Class] the type constraint for values
      # @return [void]
      def type(klass)
        @value_type = klass
      end

      # Registers a new enum entry with a unique name and value
      #
      # @param name [Symbol, String] symbolic name of the entry
      # @param value [Object] value of the entry
      # @raise [ArgumentError] if name or value is already registered
      # @raise [TypeError] if value does not match declared type
      # @return [void]
      def entry(name, value)
        name = name.to_sym
        @registry ||= {}
        @values ||= {}

        if defined?(@value_type) && !value.is_a?(@value_type)
          raise TypeError, "Invalid value type for #{name}: expected #{@value_type}, got #{value.class}"
        end

        if @values.key?(value)
          existing = @values[value]
          raise ArgumentError, "Duplicate value #{value.inspect} for #{name}; already assigned to #{existing}"
        end

        if @registry.key?(name)
          raise ArgumentError, "Duplicate name #{name}; already registered with value #{@registry[name].value.inspect}"
        end

        instance = new(value)
        @registry[name] = instance
        @values[value] = name

        define_singleton_method(name) { instance }
      end

      # Retrieves an enum instance by name
      #
      # @param name [Symbol, String]
      # @return [Kolor::Enum, nil]
      def [](name)
        @registry[name.to_sym]
      end

      # Resolves the symbolic name for a given value
      #
      # @param value [Object]
      # @return [Symbol] name or :unknown
      def name_for(value)
        @values[value] || :unknown
      end

      # Returns all registered enum instances
      #
      # @return [Array<Kolor::Enum>]
      def all
        @registry.values
      end

      # Returns all registered names
      #
      # @return [Array<Symbol>]
      def keys
        @registry.keys
      end

      # Returns all raw values
      #
      # @return [Array<Object>]
      def values
        @registry.values.map(&:value)
      end

      # Removes an enum entry by name
      #
      # @param name [Symbol, String]
      # @return [Kolor::Enum, nil] the removed entry or nil
      def remove(name)
        name = name.to_sym
        entry = @registry.delete(name)
        if entry
          @values.delete_if { |_, v| v == name }
          singleton_class.undef_method(name) if respond_to?(name)
        end
        entry
      end
    end
  end
end
