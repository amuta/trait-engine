# frozen_string_literal: true

require "trait_engine/errors"

module TraitEngine
  # A global registry of functions available in every schema.
  # Builtins are registered on load; after that REGISTRY is frozen.
  module SharedFunctions
    REGISTRY = {}.dup

    class << self
      # Register a new function under :name
      def register(name, &block)
        raise RegistryFrozenError, "registry is frozen" if REGISTRY.frozen?

        REGISTRY[name.to_sym] = block
      end

      def freeze
        REGISTRY.freeze
      end
    end

    # ─── Builtins ────────────────────────────────────────────

    register(:concatenate)   { |*args| args.join }
    register(:upcase)        { |v| v.to_s.upcase }
    register(:downcase)      { |v| v.to_s.downcase }
    register(:remove_spaces) { |v| v.to_s.gsub(" ", "") }
    register(:length)        { |v| v.to_s.length }
  end
end
