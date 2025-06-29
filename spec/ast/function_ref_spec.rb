require "trait_engine/ast/function_ref"
require "trait_engine/ast/field_ref"

RSpec.describe TraitEngine::AST::FunctionRef do
  let(:arg) { TraitEngine::AST::FieldRef.new(field_name: :x) }
  subject { described_class.new(fn_name: :compute, args: [arg]) }

  it "stores fn_name and args" do
    expect(subject.fn_name).to eq(:compute)
    expect(subject.args).to eq([arg])
  end

  it "children returns args" do
    expect(subject.children).to eq([arg])
  end
end
