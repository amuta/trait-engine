require "trait_engine/ast/trait_node"
require "trait_engine/ast/field_ref"

RSpec.describe TraitEngine::AST::TraitNode do
  let(:subject_ref) { TraitEngine::AST::FieldRef.new(field_name: :age) }
  subject { described_class.new(name: :t, subject: subject_ref, operator: :<, value: 18) }

  it "stores name, subject, operator, and value" do
    expect(subject.name).to eq(:t)
    expect(subject.subject).to eq(subject_ref)
    expect(subject.operator).to eq(:<)
    expect(subject.value).to eq(18)
  end

  it "children returns subject node" do
    expect(subject.children).to eq([subject_ref])
  end
end
