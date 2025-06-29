require_relative "node"

module TraitEngine
  module AST
    # Root of the semantic AST, holds top-level declarations
    class Schema < Node
      attr_reader :attributes, :traits, :functions

      def initialize(attributes:, traits:, functions:, loc: {})
        super(loc: loc)
        @attributes = attributes    # Array<AttributeNode>
        @traits     = traits        # Array<TraitNode>
        @functions  = functions     # Array<FunctionNode>
      end

      def children
        attributes + traits + functions
      end
    end
  end
end
