# frozen_string_literal: true

require_relative "decision_table"

module TraitEngine
  module Runtime
    class Attribute
      attr_reader :name, :kind, :resolver, :table

      def initialize(name:, value_from:)
        @name = name.to_sym

        if value_from.is_a?(DecisionTable)
          @kind = :conditional
          @table = value_from
        else
          @kind = :simple
          @resolver = value_from
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
end
