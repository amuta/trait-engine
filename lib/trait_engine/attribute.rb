# frozen_string_literal: true

require_relative "decision_table"

module TraitEngine
  class Attribute
    attr_reader :name, :kind

    def initialize(name:, resolver_or_table:)
      @name = name.to_sym

      if resolver_or_table.is_a?(TraitEngine::DecisionTable)
        @kind = :conditional
        @table = resolver_or_table
      else
        @kind = :simple
        @resolver = resolver_or_table
      end
    end

    # Dependencies (attributes/functions) for graph building
    def deps
      resolvers = simple? ? [@resolver] : @table.rows.map(&:resolver)
      resolvers.flat_map { |o| o.respond_to?(:deps) ? o.deps : [] }.uniq
    end

    def value(processor, ctx, matched_traits)
      resolver = simple? ? @resolver : @table.pick(matched_traits)
      resolver.value(processor, ctx)
    end

    def simple? = @kind == :simple
  end
end
