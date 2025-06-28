require "trait_engine/runtime/resolvers/field"

RSpec.describe TraitEngine::Runtime::Resolvers::Field do
  let(:ctx) { { login: "alice", age: 42 } }
  subject(:resolver) { described_class.new(:login) }

  it "reports its type_symbol" do
    expect(resolver.type_symbol).to eq(:field)
  end

  it "fetches the value from the context" do
    expect(resolver.value(nil, ctx)).to eq("alice")
    expect(resolver.value(nil, ctx)).to eq(ctx[:login])
  end

  it "shows a nice descriptor" do
    expect(resolver.descriptor).to eq("field:login")
  end
end
