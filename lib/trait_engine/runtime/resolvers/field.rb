# frozen_string_literal: true

require_relative "resolver_base"

module TraitEngine
  module Runtime
    module Resolvers
      # Primitive resolver that simply reads a key from the context hash.
      # e.g. field:login → ctx[:login]
      class Field < ResolverBase
        def initialize(name)
          @name = name.to_sym
        end

        def type_symbol = :field

        def value(_processor, ctx)
          ctx[@name]
        end

        private

        def display_value = @name
      end
    end
  end
end
