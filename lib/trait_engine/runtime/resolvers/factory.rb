# frozen_string_literal: true

require_relative "resolver_base"
require_relative "field"
require_relative "literal"
require_relative "function"

module TraitEngine
  module Runtime
    module Resolvers
      # Build the correct Resolver for a parsed ValueDescriptor.
      # Keeps all logic in one place so compiler and processor stay clean.
      class Factory
        def self.build(descriptor)
          case descriptor.type
          when :field    then Field.new(descriptor.value)
          when :literal  then Literal.new(descriptor.value)
          when :function
            # descriptor.value == [function_name, arg_descriptors]
            name, args = descriptor.value
            Function.new(name, args)
          else
            raise TraitEngine::Error, "unknown resolver type: #{descriptor.type}"
          end
        end
      end
    end
  end
end
