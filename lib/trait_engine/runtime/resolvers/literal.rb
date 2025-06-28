# frozen_string_literal: true

require_relative "resolver_base"

module TraitEngine
  module Runtime
    module Resolvers
      # Primitive resolver that always returns a fixed value.
      # e.g. literal:"WELCOME" → "WELCOME"
      class Literal < ResolverBase
        def initialize(value)
          @value = value
        end

        def type_symbol = :literal

        def value(_processor, _ctx)
          @value
        end

        private

        def display_value = @value.inspect
      end
    end
  end
end
