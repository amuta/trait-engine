# frozen_string_literal: true

require "trait_engine"

RSpec.describe TraitEngine::AST::SchemaNode do
  let(:loc) { TraitEngine::AST::Location.new(file: "s.yml", line: 0, column: 0) }
  let(:t1)  { TraitEngine::AST::TraitNode.new(name: :a, predicate_descriptor: proc {}, loc: loc) }
  let(:f1)  { TraitEngine::AST::FunctionNode.new(name: :f, method_name: :m, arg_descriptors: [], loc: loc) }
  let(:c1)  do
    TraitEngine::AST::ConditionalCaseNode.new(trait_names: [], resolver_descriptor: { type: :literal, value: "X" },
                                              loc: loc)
  end
  let(:a1) { TraitEngine::AST::AttributeNode.new(name: :a1, cases: [c1], loc: loc) }

  subject(:schema) { described_class.new(traits: [t1], functions: [f1], attributes: [a1], loc: loc) }

  it "to_h nests all child to_h results" do
    expect(schema.to_h).to eq(
      traits: [t1.to_h],
      functions: [f1.to_h],
      attributes: [a1.to_h],
      loc: loc.to_h
    )
  end
end
