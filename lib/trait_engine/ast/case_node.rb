require_relative "node"

module TraitEngine
  module AST
    # One row in a cascade: guarded by traits, resolved via resolver
    class CaseNode < Node
      attr_reader :traits, :resolver # Array<Symbol>, ResolverDescriptor

      def initialize(traits:, resolver:, loc: {})
        super(loc: loc)
        @traits   = traits
        @resolver = resolver
      end

      def children
        [resolver]
      end
    end
  end
end
