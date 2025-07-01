require "forwardable"

module TraitEngine
  module Parser
    class DslCascadeBuilder
      extend Forwardable

      attr_reader :cases, :default

      def_delegators :@context, :ref, :literal, :field, :call

      def initialize(context)
        @context = context
        @cases   = []
        @default = nil
      end

      def on_trait(trait_name, expr)
        loc = @context.send(:current_location)
        condition = ref(trait_name)
        result    = @context.send(:ensure_syntax, expr, loc)
        @cases << [condition, result]
      end

      def on_traits(*trait_names, expr)
        loc = @context.send(:current_location)
        condition = call(:all?, trait_names.map { |name| ref(name) })
        result    = @context.send(:ensure_syntax, expr, loc)
        @cases << [condition, result]
      end

      def default(expr = :__no_arg)
        if expr == :__no_arg__
          @default
        else
          loc = @context.send(:current_location)
          @default = @context.send(:ensure_syntax, expr, loc)
        end
      end
    end
  end
end
