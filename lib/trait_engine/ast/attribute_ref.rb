require_relative "node"

module TraitEngine
  module AST
    # References another attribute defined in the schema
    class AttributeRef < Node
      attr_reader :attribute_name

      # attribute_name: Symbol matching an AttributeNode.name
      def initialize(attribute_name:, loc: {})
        super(loc: loc)
        @attribute_name = attribute_name
      end

      # No nested children
      def children
        []
      end
    end
  end
end
