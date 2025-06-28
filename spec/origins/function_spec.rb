# frozen_string_literal: true

require "trait_engine"

RSpec.describe TraitEngine::Resolvers::Function do
  before do
    TraitEngine::Registry.reset_for_reload!
    TraitEngine::Registry.register(:concat) { |*a| a.join }
  end

  let(:processor_stub) do
    Class.new do
      def initialize(attr_values, fn_values = {})
        @attrs = attr_values
        @fns = fn_values
      end

      def resolve_attribute(name, _ctx) = @attrs[name]
      def resolve_function(name, _ctx) = @fns[name]
    end
  end

  it "evaluates nested literals & attributes" do
    arg_list = [
      { type: :literal,    value: "hi-" },
      { type: :attribute,  value: :login }
    ]
    fn_resolver = described_class.new(:concat, arg_list)
    stub_proc = processor_stub.new({ login: "bob" })

    expect(fn_resolver.value(stub_proc, {})).to eq("hi-bob")
    expect(fn_resolver.deps).to eq([:login])
  end
end
