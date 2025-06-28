module TraitEngine
  module Parse
    module Lexer
      Token = Struct.new(:kind, :text, :loc) do
        def to_s = "#{kind}(#{text}) @#{loc}"
        def to_h = { kind: kind, text: text, loc: loc.to_h }
      end
    end
  end
end
