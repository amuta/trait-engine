module TraitEngine
  module Syntax
    Location = Struct.new(:file, :line, :column, keyword_init: true) do
      def to_s = "#{file}:#{line}:#{column}"
      def to_h = { file: file, line: line, column: column }
    end
  end
end
