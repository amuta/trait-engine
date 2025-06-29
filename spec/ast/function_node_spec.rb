require "trait_engine/ast/function_node"
require "trait_engine/ast/literal_ref"

RSpec.describe TraitEngine::AST::FunctionNode do
  let(:arg1) { TraitEngine::AST::LiteralRef.new(value: 42) }
  let(:arg2) { TraitEngine::AST::LiteralRef.new(value: "foo") }
  subject { described_class.new(name: :f, fn_name: :baz, args: [arg1, arg2]) }

  it "stores name, fn_name, and args" do
    expect(subject.name).to eq(:f)
    expect(subject.fn_name).to eq(:baz)
    expect(subject.args).to eq([arg1, arg2])
  end

  it "children returns args" do
    expect(subject.children).to eq([arg1, arg2])
  end
end
