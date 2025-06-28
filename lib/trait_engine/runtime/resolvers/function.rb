# frozen_string_literal: true

require_relative "resolver_base"

module TraitEngine
  module Runtime
    module Resolvers
      # Composite resolver that invokes a compiled Function wrapper.
      # It acts as a leaf in an attribute’s decision table,
      # but under the covers will evaluate its arguments.
      class Function < ResolverBase
        def initialize(name, arg_descriptors)
          @name            = name.to_sym
          @arg_descriptors = arg_descriptors.freeze
        end

        def type_symbol = :function

        def deps
          @arg_descriptors
            .select { |d| %i[field attribute function].include?(d[:type]) }
            .map    { |d| d[:value] }
        end

        def value(processor, ctx)
          fn = processor.schema.fetch_function(@name)
          raise Error, "undefined function #{@name}" unless fn

          fn.call(processor, ctx)
        end

        private

        def display_value = @name
      end
    end
  end
end
