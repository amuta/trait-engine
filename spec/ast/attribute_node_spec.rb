require "trait_engine/ast/attribute_node"
require "trait_engine/ast/case_node"

RSpec.describe TraitEngine::AST::AttributeNode do
  let(:case_node) { TraitEngine::AST::CaseNode.new(traits: [], resolver: double) }
  subject { described_class.new(name: :attr, case_nodes: [case_node]) }

  it "stores name and cases" do
    expect(subject.name).to eq(:attr)
    expect(subject.case_nodes).to eq([case_node])
  end

  it "children returns case_nodes" do
    expect(subject.children).to eq([case_node])
  end
end
