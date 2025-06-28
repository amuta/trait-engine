# frozen_string_literal: true

require "trait_engine/syntax/nodes/function"

RSpec.describe TraitEngine::Syntax::Nodes::Function do
  let(:loc) { double("Location", to_h: { start_line: 1, end_line: 2 }) }
  let(:args) { [{ type: :literal, value: "X" }] }
  subject(:node) do
    described_class.new(
      name: :foo_fn,
      method_name: :bar,
      arg_descriptors: args,
      loc: loc
    )
  end

  it "stores name, method_name, arg_descriptors, and loc" do
    expect(node.name).to eq(:foo_fn)
    expect(node.method_name).to eq(:bar)
    expect(node.arg_descriptors).to eq(args)
    expect(node.loc).to eq(loc)
  end

  it "to_h outputs the full hash" do
    expect(node.to_h).to eq(
      type: :function,
      name: :foo_fn,
      method: :bar,
      args: args,
      loc: loc.to_h
    )
  end
end
