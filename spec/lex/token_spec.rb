require "trait_engine"

RSpec.describe TraitEngine::Lex::Token do
  it "can create a token with kind and text" do
    loc = TraitEngine::AST::Location.new(file: "x", line: 1, column: 3)
    tok = TraitEngine::Lex::Token.new(kind: :kw_field, text: "field:", loc: loc)
    expect(tok.to_s).to eq("kw_field(field:) @x:1:3")
  end
end
