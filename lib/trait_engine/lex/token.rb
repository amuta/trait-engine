module TraitEngine
  # Convert scalar string "field:login" into tokens with file/line info.
  module Lex
    Token = Struct.new(:kind, :text, :loc, keyword_init: true) do
      def to_s = "#{kind}(#{text}) @#{loc}"
      def to_h = { kind: kind, text: text, loc: loc.to_h }
    end
  end
end
