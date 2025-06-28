require "trait_engine"

RSpec.describe TraitEngine::Classify::ResolverClassifier do
  it "correctly classifies tokens" do
    lexer = TraitEngine::Parse::Lexer::ScalarLexer.new("field:login", file: "x")
    tokens = lexer.tokens
    desc   = described_class.from_tokens(tokens)
    expect(desc).to eq({ type: :field, value: :login })
  end
end
