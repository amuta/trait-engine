# frozen_string_literal: true

require "trait_engine"

FIXTURE = File.join(__dir__, "..", "fixtures", "complex_schema.yml")

RSpec.describe TraitEngine::Loaders::YamlLoader do
  subject(:ast) { described_class.load(FIXTURE) }

  it "returns an Syntax::Schema" do
    expect(ast).to be_a(TraitEngine::Syntax::Nodes::Schema)
  end

  it "captures all attribute names" do
    names = ast.attributes.map(&:name)
    expect(names).to contain_exactly(:login, :tier, :region, :promo_code)
  end

  context "promo_code attribute" do
    let(:promo_attr) { ast.attributes.find { |a| a.name == :promo_code } }

    it "is conditional (has two cases)" do
      expect(promo_attr.cases.size).to eq(2)
    end

    it "first case references gold & eu traits with a function resolver" do
      first_case = promo_attr.cases.first
      expect(first_case.trait_names).to eq(%i[gold_tier eu_region])
      expect(first_case.resolver_descriptor.to_h)
        .to eq(type: :function, value: [:promo_gold_eu, []])
    end

    it "default case uses literal resolver" do
      default_case = promo_attr.cases.last
      expect(default_case.trait_names).to eq([])
      expect(default_case.resolver_descriptor.to_h)
        .to eq(type: :literal, value: "WELCOME")
    end
  end
end
