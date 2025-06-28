require "trait_engine/runtime/resolvers/literal"

RSpec.describe TraitEngine::Runtime::Resolvers::Literal do
  subject(:resolver) { described_class.new("XYZ") }

  it "reports its type_symbol" do
    expect(resolver.type_symbol).to eq(:literal)
  end

  it "always returns the literal value" do
    expect(resolver.value(nil, {})).to eq("XYZ")
  end

  it "shows a quoted descriptor" do
    expect(resolver.descriptor).to eq('literal:"XYZ"')
  end
end
