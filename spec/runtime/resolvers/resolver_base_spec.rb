require "trait_engine/runtime/resolvers/resolver_base"

RSpec.describe TraitEngine::Runtime::Resolvers::ResolverBase do
  it "raises on #value by default" do
    klass = Class.new(described_class) do
      def type_symbol = :foo
    end
    inst = klass.new
    expect { inst.value(nil, {}) }.to raise_error(NotImplementedError)
  end

  it "defaults #deps to empty array" do
    inst = described_class.new
    expect(inst.deps).to eq([])
  end

  it "builds a descriptor string" do
    inst = Class.new(described_class) do
      def type_symbol = :foo
      def display_value = "bar"
    end.new
    expect(inst.descriptor).to eq("foo:bar")
  end
end
