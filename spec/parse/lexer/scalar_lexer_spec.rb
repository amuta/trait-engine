require "trait_engine/parse/lexer/scalar_lexer"

RSpec.describe TraitEngine::Parse::Lexer::ScalarLexer do
  it "tokenizes field declaration" do
    lex = described_class.new("field:login", file: "rule.yml")
    kinds = lex.tokens.map(&:kind)
    expect(kinds).to eq(%i[kw_field colon ident])
  end

  it "tokenizes trait predicates" do
    lexer  = TraitEngine::Parse::Lexer::ScalarLexer.new("attribute:tier >= gold", file: "x")
    kinds  = lexer.tokens.map(&:kind)

    expect(kinds).to eq(%i[kw_attribute colon ident op ident])

    lexer  = TraitEngine::Parse::Lexer::ScalarLexer.new("field:tier >= gold", file: "x")
    kinds  = lexer.tokens.map(&:kind)

    expect(kinds).to eq(%i[kw_field colon ident op ident])
  end
end
