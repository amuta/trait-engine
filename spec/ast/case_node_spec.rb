require "trait_engine/ast/case_node"

RSpec.describe TraitEngine::AST::CaseNode do
  let(:resolver) { double(:resolver) }
  subject { described_class.new(traits: %i[a b], resolver: resolver) }

  it "stores traits and resolver" do
    expect(subject.traits).to eq(%i[a b])
    expect(subject.resolver).to eq(resolver)
  end

  it "children returns resolver as single element" do
    expect(subject.children).to eq([resolver])
  end
end
