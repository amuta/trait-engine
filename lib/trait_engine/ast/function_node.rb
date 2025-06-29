module TraitEngine
  module AST
    # A computation declaration; args can be literals, field refs, or nested functions
    class FunctionNode < Node
      attr_reader :name, :fn_name, :args

      # fn_name: Symbol, args: Array<LiteralRef|FieldRef|FunctionRef>
      def initialize(name:, fn_name:, args:, loc: {})
        super(loc: loc)
        @name    = name
        @fn_name = fn_name
        @args    = args
      end

      def children
        args
      end
    end
  end
end
