# frozen_string_literal: true

require "trait_engine/parse/lexer/scalar_lexer"
require "trait_engine/parse/classifier/predicate_parser"

Lexer  = TraitEngine::Parse::Lexer::ScalarLexer
Parser = TraitEngine::Parse::Classifier::PredicateParser

RSpec.describe Parser do
  def parse(str)
    tokens = Lexer.new(str, file: "test.yml").tokens
    Parser.from_tokens(tokens)
  end

  context "happy paths" do
    it "parses unquoted identifier rhs" do
      desc = parse("attribute:tier == gold")
      expect(desc).to eq(
        lhs: { type: :attribute, value: :tier },
        op: :eq,
        rhs: { type: :literal, value: "gold" }
      )
    end

    it "parses numeric rhs" do
      desc = parse("field:qty > 10")
      expect(desc).to eq(
        lhs: { type: :field, value: :qty },
        op: :gt,
        rhs: { type: :literal, value: 10 }
      )
    end

    it "parses single-quoted string rhs" do
      desc = parse("field:region == 'EU'")
      expect(desc[:rhs][:value]).to eq("EU")
    end

    it "parses double-quoted string rhs" do
      desc = parse('field:role != "intern"')
      expect(desc[:rhs][:value]).to eq("intern")
    end
  end

  context "error cases" do
    it "raises on invalid predicate syntax" do
      tokens = Lexer.new("field:x not_operator 1", file: "x").tokens
      expect { Parser.from_tokens(tokens) }
        .to raise_error(TraitEngine::ValidationError, /invalid predicate syntax/)
    end

    it "raises on invalid lhs keyword" do
      tokens = Lexer.new("foo:bar > 1", file: "x").tokens
      expect { Parser.from_tokens(tokens) }
        .to raise_error(TraitEngine::ValidationError, /lhs must be attribute: or field:/)
    end
  end
end
