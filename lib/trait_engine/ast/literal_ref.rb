require_relative "node"

module TraitEngine
  module AST
    # Wraps a literal value in the AST
    class LiteralRef < Node
      attr_reader :value

      def initialize(value:, loc: {})
        super(loc: loc)
        @value = value
      end
    end
  end
end
