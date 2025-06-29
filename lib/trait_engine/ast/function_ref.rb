require_relative "node"

module TraitEngine
  module AST
    # References a nested function call in arguments
    class FunctionRef < Node
      attr_reader :fn_name, :args # Symbol, Array<LiteralRef|FieldRef|FunctionRef>

      def initialize(fn_name:, args:, loc: {})
        super(loc: loc)
        @fn_name = fn_name
        @args    = args
      end

      def children
        args
      end
    end
  end
end
