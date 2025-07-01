require_relative "node"

module TraitEngine
  module Syntax
    module Expressions
      CallExpression = Struct.new(:fn_name, :args) do
        include Node
        def children = args
      end

      CascadeExpression = Struct.new(:cases, :default) do
        include Node
        def children = cases.flat_map(&:flatten) + [default].compact
      end

      ListExpression = Struct.new(:elements) do
        include Node
        def children = elements
      end
    end
  end
end
