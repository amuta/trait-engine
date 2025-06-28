# frozen_string_literal: true

require "trait_engine"

Loader   = TraitEngine::Loaders::YamlLoader
Compiler = TraitEngine::SchemaCompiler
Processor = TraitEngine::Processor
FIXTURE = File.join(__dir__, "..", "fixtures", "complex_schema.yml")

RSpec.describe Processor do
  let(:schema)  { Compiler.compile(Loader.load(FIXTURE)) }
  let(:ctx)     { { login: "bob", tier: "gold", region: "EU", order_total_cents: 5000 } }
  subject(:proc) { Processor.new(schema) }

  it "resolves promo_code end-to-end" do
    pending "resolve_attribute"
    expect(proc.resolve_attribute(:promo_code, ctx)).to eq("bob_GE")
  end

  it "memoises values" do
    pending "memo + matched_traits cache"
    proc.resolve_attribute(:promo_code, ctx)
    expect(proc.instance_variable_get(:@memo).size).to be > 1
  end

  it "builds explain trace" do
    pending "explain"
    proc.resolve_attribute(:promo_code, ctx)
    trace = proc.explain(:promo_code, ctx)
    expect(trace).to include(:resolver, :deps)
  end

  it "detects runtime cycles" do
    pending "detect_cycle!"
    cyc_schema = TraitEngine::Schema.new(attributes: {}) # create artificial cycle later
    # ...
  end
end
