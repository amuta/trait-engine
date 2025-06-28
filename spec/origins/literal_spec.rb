# frozen_string_literal: true

require "trait_engine"

RSpec.describe TraitEngine::Resolvers::Literal do
  let(:lit) { described_class.new("xyz") }

  it "returns stored value" do
    expect(lit.value).to eq("xyz")
  end

  it "exposes descriptor" do
    expect(lit.descriptor).to eq('literal:"xyz"')
  end
end
