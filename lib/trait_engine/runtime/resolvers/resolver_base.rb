# frozen_string_literal: true

module TraitEngine
  module Runtime
    module Resolvers
      # The abstract interface for *any* value resolver.
      # Subclasses must implement:
      #   • #type_symbol  — a short symbol id (e.g. :field, :literal, :function)
      #   • #value(proc, ctx) — produce the runtime value
      #   • #descriptor  — human-readable form of this origin
      # May override:
      #   • #deps         — nested dependencies (defaults to [])
      class ResolverBase
        def type_symbol
          raise NotImplementedError, "#{self.class} must implement #type_symbol"
        end

        def deps
          []
        end

        def value(_processor, _ctx)
          raise NotImplementedError, "#{self.class} must implement #value"
        end

        def descriptor
          "#{type_symbol}:#{display_value}"
        end

        private

        def display_value
          "<?>" # override to show a meaningful name/value
        end
      end
    end
  end
end
