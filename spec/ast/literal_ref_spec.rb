require "trait_engine/ast/literal_ref"

RSpec.describe TraitEngine::AST::LiteralRef do
  subject { described_class.new(value: "bar") }

  it "stores the literal value" do
    expect(subject.value).to eq("bar")
  end

  it "has no children" do
    expect(subject.children).to eq([])
  end
end
