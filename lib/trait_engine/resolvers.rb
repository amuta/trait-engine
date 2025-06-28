# frozen_string_literal: true

require_relative "registry"

module TraitEngine
  module Resolvers
    class Base
      def type_symbol
        raise NotImplementedError
      end

      def deps
        []
      end

      def value(_processor, _ctx)
        raise NotImplementedError
      end

      # Pretty id for debugging (`literal:"foo"`, `column:tier`, ...)
      def descriptor
        "#{type_symbol}:#{display_value}"
      end

      private

      # override for nicer descriptor output
      def display_value
        "<?>"
      end
    end

    class Factory
      # Build resolver from DSL/YAML tokens.
      #
      # @param type  [Symbol]  :literal | :field | :function
      # @param value [Object]  payload (string, symbol, array …)
      #
      def self.build(type:, value:)
        case type.to_sym
        when :literal then Literal.new(value)
        when :field then Field.new(value)
        when :function
          fn_name, arg_descs = value
          Function.new(fn_name, arg_descs)
        else
          raise TraitEngine::Error, "unknown resolver type #{type}"
        end
      end
    end

    class Field < Base
      def initialize(name)
        @name = name.to_sym
      end

      def type_symbol = :field
      def value(_, ctx) = ctx[@name]

      private

      def display_value = @name
    end

    class Function < Base
      Arg = Struct.new(:type, :value, keyword_init: true)

      attr_reader :name, :args

      def initialize(name, arg_descriptors)
        @name = name.to_sym
        @args = arg_descriptors.map { |h| Arg.new(**h) }
      end

      def type_symbol = :function

      def deps
        args.filter { |a| %i[attribute function].include?(a.type) }
            .map(&:value)
      end

      def value(processor, ctx)
        func = TraitEngine::Registry.fetch(@name)

        evaluated = args.map do |arg|
          case arg.type
          when :literal   then arg.value
          when :attribute then processor.resolve_attribute(arg.value, ctx)
          when :function  then processor.resolve_function(arg.value, ctx)
          else
            raise TraitEngine::Error, "unknown arg type #{arg.type}"
          end
        end

        func.call(*evaluated)
      end

      private

      def display_value = @name
    end

    class Literal < Base
      def initialize(value)
        @value = value
      end

      def type_symbol = :literal
      def value(*)    = @value

      private

      def display_value = @value.inspect
    end
  end
end
