# frozen_string_literal: true

require "trait_engine/shared_functions/core"

module TraitEngine
  module Runtime
    # Runtime container for a single compiled rule set.
    #
    #  • `traits`     – { Symbol => Trait }
    #  • `functions`  – { Symbol => Function }
    #  • `attributes` – { Symbol => Attribute }
    #
    class Schema
      attr_reader :traits, :functions, :attributes

      def initialize(traits: {}, functions: {}, attributes: {})
        @traits     = traits.freeze
        @functions  = functions.freeze
        @attributes = attributes.freeze
      end

      # ------------------------------------------------------------------
      # Lookup helpers
      # ------------------------------------------------------------------

      def fetch_trait(name)
        traits[name.to_sym]
      end

      # Returns Proc or nil
      def fetch_function(name)
        functions.fetch(name.to_sym) do
          raise UnknownFunctionError, "function not defined in this schema: #{name}"
        end
      end

      def fetch_attribute(name)
        attributes[name.to_sym]
      end
    end
  end
end
