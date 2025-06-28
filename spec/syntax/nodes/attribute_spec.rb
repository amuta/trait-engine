# frozen_string_literal: true

require "trait_engine/syntax/nodes/attribute"

RSpec.describe TraitEngine::Syntax::Nodes::Attribute do
  let(:loc)    { double("Location", to_h: { start_line: 1, end_line: 2 }) }
  let(:case1) { double("CaseNode", to_h: { type: "case1" }, loc: loc, trait_names: []) }
  let(:case2) { double("CaseNode", to_h: { type: "case2" }, loc: loc) }
  let(:case3) { double("CaseNode", to_h: { type: "case3" }, loc: loc, trait_names: [:trait1]) }

  it "detects simple? correctly" do
    simple = described_class.new(name: :foo, cases: [case1], loc: loc)
    complex = described_class.new(name: :bar, cases: [case2, case1], loc: loc)
    not_simple = described_class.new(name: :baz, cases: [case3], loc: loc)

    expect(simple.simple?).to be true
    expect(complex.simple?).to be false
    expect(not_simple.simple?).to be false
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
