# frozen_string_literal: true

require "trait_engine"

RSpec.describe TraitEngine::AST::AttributeNode do
  let(:loc)    { TraitEngine::AST::Location.new(file: "a.yml", line: 1, column: 1) }
  let(:case1) do
    TraitEngine::AST::ConditionalCaseNode.new(trait_names: [], resolver_descriptor: { type: :literal, value: "X" },
                                              loc: loc)
  end
  let(:case2) do
    TraitEngine::AST::ConditionalCaseNode.new(trait_names: [:t], resolver_descriptor: { type: :literal, value: "Y" },
                                              loc: loc)
  end

  it "detects simple? correctly" do
    simple = described_class.new(name: :foo, cases: [case1], loc: loc)
    complex = described_class.new(name: :bar, cases: [case2, case1], loc: loc)

    expect(simple.simple?).to be true
    expect(complex.simple?).to be false
  end

  it "to_h outputs name, cases array, and loc" do
    node = described_class.new(name: :foo, cases: [case1], loc: loc)
    expect(node.to_h).to eq(
      name: :foo,
      cases: [case1.to_h],
      loc: loc.to_h
    )
  end
end
