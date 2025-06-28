# frozen_string_literal: true

require "trait_engine/attribute"

RSpec.describe TraitEngine::Attribute do
  let(:lit_hello)   { TraitEngine::Resolvers::Literal.new("HELLO") }
  let(:lit_default) { TraitEngine::Resolvers::Literal.new("DEF") }

  let(:table) do
    TraitEngine::DecisionTable.new([
                                     [[:shout], lit_hello],
                                     [[], lit_default]
                                   ])
  end

  let(:attr_simple) { described_class.new(name: :greet, resolver_or_table: lit_hello) }
  let(:attr_cond)   { described_class.new(name: :msg,   resolver_or_table: table) }

  it "returns deps for simple resolver" do
    expect(attr_simple.deps).to eq([])
  end

  it "returns deps aggregate for conditional resolver" do
    expect(attr_cond.deps).to eq([])
  end

  it "evaluates simple attribute" do
    processor_stub = double("ProcStub")
    expect(attr_simple.value(processor_stub, {}, Set[])).to eq("HELLO")
  end

  it "evaluates conditional attribute based on traits" do
    proc_stub = double("ProcStub")
    result = attr_cond.value(proc_stub, {}, Set[:shout])
    expect(result).to eq("HELLO")
  end
end
