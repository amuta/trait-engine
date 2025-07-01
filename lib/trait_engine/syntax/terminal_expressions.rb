require_relative "node"

module TraitEngine
  module Syntax
    module TerminalExpressions
      # Leaf expressions that represent a value or reference and terminate a branch.

      Literal = Struct.new(:value) do
        include Node
        def children = []
      end
      Field = Struct.new(:name) do
        include Node
        def children = []
      end
      Binding = Struct.new(:name) do
        include Node
        def children = []
      end
    end
  end
end
