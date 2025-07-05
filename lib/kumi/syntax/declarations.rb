require_relative "node"

module Kumi
  module Syntax
    module Declarations
      Attribute = Struct.new(:name, :expression) do
        include Node
        def children = [expression]
      end

      Trait = Struct.new(:name, :expression) do
        include Node
        def children = [expression]
      end

      Function = Struct.new(:name, :expression) do
        include Node
        def children = [expression]
      end
    end
  end
end
