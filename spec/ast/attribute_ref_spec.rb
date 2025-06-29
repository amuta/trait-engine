require "trait_engine/ast/attribute_ref"

RSpec.describe TraitEngine::AST::AttributeRef do
  let(:loc) { { file: "schema.rb", line: 10, column: 5 } }
  subject { described_class.new(attribute_name: :foo, loc: loc) }

  it "stores the attribute_name" do
    expect(subject.attribute_name).to eq(:foo)
  end

  it "retains location metadata" do
    expect(subject.loc).to eq(loc)
  end

  it "has no children" do
    expect(subject.children).to eq([])
  end
end
