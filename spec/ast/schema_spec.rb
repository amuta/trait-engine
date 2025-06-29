require "trait_engine/ast/schema"
require "trait_engine/ast/attribute_node"
require "trait_engine/ast/trait_node"
require "trait_engine/ast/function_node"

RSpec.describe TraitEngine::AST::Schema do
  let(:attr) { TraitEngine::AST::AttributeNode.new(name: :foo, case_nodes: []) }
  let(:trait) { TraitEngine::AST::TraitNode.new(name: :t, subject: nil, operator: :==, value: 1) }
  let(:fn)    { TraitEngine::AST::FunctionNode.new(name: :f, fn_name: :bar, args: []) }
  subject { described_class.new(attributes: [attr], traits: [trait], functions: [fn]) }

  it "holds attributes, traits, and functions" do
    expect(subject.attributes).to contain_exactly(attr)
    expect(subject.traits).to contain_exactly(trait)
    expect(subject.functions).to contain_exactly(fn)
  end

  it "children includes all nodes" do
    expect(subject.children).to match_array([attr, trait, fn])
  end
end
