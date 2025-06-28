# frozen_string_literal: true

require "trait_engine"
require "set"

RSpec.describe TraitEngine::DecisionTable do
  let(:resolver_a) { { type: :literal, value: "A" } }
  let(:resolver_b) { { type: :literal, value: "B" } }
  let(:resolver_default) { { type: :literal, value: "DEF" } }

  let(:table) do
    rows = [
      [%i[gold eu], resolver_a],
      [[:gold],      resolver_b],
      [[],           resolver_default]
    ]
    described_class.new(rows)
  end

  it "picks the first row whose traits are satisfied" do
    set = Set[:gold, :eu]
    expect(table.pick(set)).to eq(resolver_a)
  end

  it "falls back to lower-specificity rows" do
    expect(table.pick(Set[:gold])).to   eq(resolver_b)
    expect(table.pick(Set[:bronze])).to eq(resolver_default)
  end
end
