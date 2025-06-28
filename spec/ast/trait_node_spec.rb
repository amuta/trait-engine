# frozen_string_literal: true

require "trait_engine"

RSpec.describe TraitEngine::AST::TraitNode do
  let(:loc)  { TraitEngine::AST::Location.new(file: "a.rb", line: 10, column: 2) }
  let(:pred) { { lhs: {}, op: nil, rhs: {} } }

  subject(:node) { described_class.new(name: :foo, predicate_descriptor: pred, loc: loc) }

  it "stores name, predicate_block, and loc" do
    expect(node.name).to eq(:foo)
    expect(node.predicate_descriptor).to eq(pred)
    expect(node.loc).to eq(loc)
  end

  it "to_h includes type, name, and loc hash" do
    expect(node.to_h).to eq({ type: :trait, name: :foo, loc: loc.to_h })
  end
end
