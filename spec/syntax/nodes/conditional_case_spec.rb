# frozen_string_literal: true

require "trait_engine/syntax/nodes/conditional_case"

RSpec.describe TraitEngine::Syntax::Nodes::ConditionalCase do
  let(:loc) { double("Location", to_h: { start_line: 1, end_line: 2 }) }
  let(:desc)  { { type: :literal, value: "V" } }
  subject(:node) do
    described_class.new(trait_names: %i[a b], resolver_descriptor: desc, loc: loc)
  end

  it "stores trait_names, resolver_descriptor, and loc" do
    expect(node.trait_names).to eq(%i[a b])
    expect(node.resolver_descriptor).to eq(desc)
    expect(node.loc).to eq(loc)
  end

  it "to_h outputs a hash with traits, resolver, loc" do
    expect(node.to_h).to eq(
      traits: %i[a b],
      resolver: desc,
      loc: loc.to_h
    )
  end
end
