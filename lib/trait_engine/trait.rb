# frozen_string_literal: true

require_relative "errors"

module TraitEngine
  # A reusable boolean predicate («trait») labelled with a name.
  #
  # @example   Trait.new(:gold) { |ctx| ctx[:tier] == "gold" }
  #
  class Trait
    attr_reader :name, :predicate

    def initialize(name, &predicate)
      raise ArgumentError, "block required for trait #{name}" unless block_given?

      @name      = name.to_sym
      @predicate = predicate
    end

    # Evaluate against a context hash
    #
    # @param ctx [Hash] record or attribute hash
    # @return [Boolean]
    def call(ctx)
      !!@predicate.call(ctx)
    rescue StandardError => e
      raise TraitEngine::Error, "trait #{@name} failed: #{e.message}"
    end
  end
end
