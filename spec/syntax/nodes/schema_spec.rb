# frozen_string_literal: true

require "trait_engine/syntax/nodes/schema"

RSpec.describe TraitEngine::Syntax::Nodes::Schema do
  let(:loc) { double("Location", to_h: { start_line: 1, end_line: 2 }) }
  let(:t1)  { double("TraitNode", to_h: { type: :trait, name: :trait1 }, loc: loc) }
  let(:f1)  { double("FunctionNode", to_h: { type: :function, name: :func1, method: :method1, args: [] }, loc: loc) }
  let(:a1)  { double("AttributeNode", to_h: { name: :attr1, cases: [], loc: loc }, loc: loc) }

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
