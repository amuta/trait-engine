require_relative "node"

module TraitEngine
  module AST
    # A boolean predicate declaration
    class TraitNode < Node
      attr_reader :name, :subject, :operator, :value

      # subject: Symbol or FunctionRef, operator: Symbol, value: any
      def initialize(name:, subject:, operator:, value:, loc: {})
        super(loc: loc)
        @name     = name
        @subject  = subject
        @operator = operator
        @value    = value
      end

      def children
        [subject].compact
      end
    end
  end
end
