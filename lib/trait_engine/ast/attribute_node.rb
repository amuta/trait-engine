require_relative "node"

module TraitEngine
  module AST
    # Represents an attribute declaration, simple or cascade
    class AttributeNode < Node
      attr_reader :name, :case_nodes

      # case_nodes: Array<CaseNode>
      def initialize(name:, case_nodes:, loc: {})
        super(loc: loc)
        @name       = name
        @case_nodes = case_nodes
      end

      def children
        case_nodes
      end
    end
  end
end
