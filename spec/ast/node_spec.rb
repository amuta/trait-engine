require "trait_engine/ast/node"

RSpec.describe TraitEngine::AST::Node do
  let(:loc) { { file: "foo.rb", line: 1, column: 2 } }
  subject { described_class.new(loc: loc) }

  it "stores location metadata" do
    expect(subject.loc).to eq(loc)
  end

  it "has no children by default" do
    expect(subject.children).to eq([])
  end
end
