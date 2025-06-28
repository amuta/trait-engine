# spec/compiler/schema_compiler_spec.rb
# frozen_string_literal: true

require "trait_engine"

Loader   = TraitEngine::Loaders::YamlLoader
Compiler = TraitEngine::SchemaCompiler
FIXTURE  = File.join(__dir__, "..", "fixtures", "complex_schema.yml")

RSpec.describe Compiler do
  let(:ast)     { Loader.load(FIXTURE) }
  let(:schema)  { Compiler.compile(ast) }

  it "builds TraitEngine::Schema" do
    expect(schema).to be_a(TraitEngine::Schema)
  end

  context "traits translation" do
    it "compiles predicate lambdas" do
      pending "implement predicate_lambda"
      trait = schema.traits[:gold_tier]
      expect(trait.call(tier: "gold")).to be true
      expect(trait.call(tier: "silver")).to be false
    end
  end

  context "functions translation" do
    it "keeps schema-local functions isolated" do
      pending "build_function_obj"
      expect(schema.fetch_function(:promo_gold_eu)).to be_a(TraitEngine::Function)
    end
  end

  context "attributes translation" do
    it "creates Attribute objects with decision tables" do
      pending "compile_attributes"
      attr = schema.attributes[:promo_code]
      expect(attr).to be_a(TraitEngine::Attribute)
      expect(attr.simple?).to be false
    end
  end
end
