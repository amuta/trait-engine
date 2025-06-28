require "trait_engine/parse/lexer/token"
require "trait_engine/syntax/location"

RSpec.describe TraitEngine::Parse::Lexer::Token do
  it "can create a token with kind and text" do
    loc = TraitEngine::Syntax::Location.new(file: "x", line: 1, column: 3)
    tok = TraitEngine::Parse::Lexer::Token.new(kind: :kw_field, text: "field:", loc: )
    expect(tok.to_s).to eq("kw_field(field:) @x:1:3")
  end
end
