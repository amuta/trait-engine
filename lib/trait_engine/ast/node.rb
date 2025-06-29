module TraitEngine
  module AST
    # Base AST node with source-location metadata and child traversal

    Location = Struct.new(:file, :line, :column, keyword_init: true) do
      def to_s = "#{file}:#{line}:#{column}"
      def to_h = { file: file, line: line, column: column }
    end

    class Node
      attr_reader :loc

      def initialize(loc: Location.new)
        @loc = loc
      end

      # Override in subclasses to return nested AST nodes
      def children
        []
      end
    end
  end
end
