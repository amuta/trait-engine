require "trait_engine/ast/field_ref"

RSpec.describe TraitEngine::AST::FieldRef do
  subject { described_class.new(field_name: :foo) }

  it "stores the field name" do
    expect(subject.field_name).to eq(:foo)
  end

  it "has no children" do
    expect(subject.children).to eq([])
  end
end
