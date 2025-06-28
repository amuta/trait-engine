# frozen_string_literal: true

require "trait_engine/core_funcs" if defined?(TraitEngine::CoreFuncs)

module TraitEngine
  # Runtime container for a single compiled rule set.
  #
  #  • `traits`     – { Symbol => Trait }
  #  • `functions`  – { Symbol => Proc }  (schema-local only)
  #  • `attributes` – { Symbol => Attribute }
  #
  # Core functions (defined once at boot in `TraitEngine::CoreFuncs::REGISTRY`)
  # are NOT duplicated here; #fetch_function transparently falls back.
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
      functions[name.to_sym] ||
        (defined?(TraitEngine::CoreFuncs) && CoreFuncs::REGISTRY[name.to_sym])
    end

    def fetch_attribute(name)
      attributes[name.to_sym]
    end
  end
end
