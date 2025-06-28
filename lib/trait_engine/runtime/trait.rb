# frozen_string_literal: true

module TraitEngine
  module Runtime
    # Represents a named predicate (trait) that can be evaluated against a context.
    # A Trait encapsulates a boolean lambda that returns true or false for a given context hash.
    class Trait
      # @return [Symbol] the name of this trait
      attr_reader :name

      # @param name [#to_sym] the trait's identifier
      # @yieldparam ctx [Hash] the context data to evaluate
      def initialize(name, &predicate)
        @name = name.to_sym
        @predicate = predicate || ->(_ctx) { false }
      end

      # Evaluate this trait against the provided context.
      # @param ctx [Hash] the context keys/values for evaluation
      # @return [Boolean]
      def call(ctx)
        @predicate.call(ctx)
      end

      # For nicer debugging
      # @return [String]
      def inspect
        "#<#{self.class}:#{object_id.to_s(16)} name=#{name.inspect}>"
      end
    end
  end
end
