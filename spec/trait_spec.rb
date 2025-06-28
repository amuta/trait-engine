# frozen_string_literal: true

require "trait_engine"

RSpec.describe TraitEngine::Trait do
  let(:gold_trait) do
    described_class.new(:gold_tier) { |ctx| ctx[:tier] == "gold" }
  end

  let(:ctx_gold) { { tier: "gold", region: "EU" } }
  let(:ctx_bronze) { { tier: "bronze" } }

  describe "#call" do
    it "returns true when predicate matches" do
      expect(gold_trait.call(ctx_gold)).to be true
    end

    it "returns false when predicate fails" do
      expect(gold_trait.call(ctx_bronze)).to be false
    end
  end

  it "raises if predicate blows up with a clear message" do
    # TODO(Behaviors) - define if traits should handle exceptions gracefully
    # I think we should just return false and log the error
    # but for now, let's raise an error to make it explicit
    boom_trait = described_class.new(:boom) { |_| raise "boom" }
    expect { boom_trait.call({}) }
      .to raise_error(TraitEngine::Error, /trait boom failed: boom/)
  end

  it "requires a block at construction time" do
    expect { described_class.new(:no_block) }.to raise_error(ArgumentError)
  end
end
