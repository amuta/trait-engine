# spec/parse/classifier/resolver_classifier_spec.rb
# frozen_string_literal: true

require "trait_engine/parse/lexer/scalar_lexer"
require "trait_engine/parse/classifier/resolver_classifier"

RSpec.describe TraitEngine::Parse::Classifier::ResolverClassifier do
  let(:lexer)      { TraitEngine::Parse::Lexer::ScalarLexer }
  let(:classifier) { described_class }

  def classify(str)
    tokens = lexer.new(str, file: "spec/parse/classifier/resolver_classifier_spec.rb").tokens
    classifier.from_tokens(tokens)
  end

  describe ".from_tokens" do
    it "parses a field descriptor" do
      desc = classify("field:login")
      expect(desc).to be_a(TraitEngine::Syntax::ValueDescriptor)
      expect(desc.type).to eq(:field)
      expect(desc.value).to eq(:login)
    end

    it "parses a literal descriptor" do
      desc = classify("literal:WELCOME")
      expect(desc.type).to eq(:literal)
      expect(desc.value).to eq("WELCOME")
    end

    it "parses an attribute descriptor" do
      desc = classify("attribute:role")
      expect(desc.type).to eq(:attribute)
      expect(desc.value).to eq(:role)
    end

    it "parses a function descriptor with no args" do
      desc = classify("function:promo_code")
      expect(desc.type).to eq(:function)
      expect(desc.value).to eq([:promo_code, []])
    end

    it "raises a ValidationError on unknown patterns" do
      expect { classify("foo:bar") }
        .to raise_error(TraitEngine::ValidationError, /unknown resolver pattern/)
    end
  end
end
