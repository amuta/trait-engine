require "trait_engine/runtime/resolvers/function"

RSpec.describe TraitEngine::Runtime::Resolvers::Function do
  let(:processor) { instance_double("processor") }
  let(:schema)    { instance_double("schema") }
  let(:ctx)       { { any: "context" } }
  subject(:resolver) { described_class.new(:my_func, []) }

  before do
    allow(processor).to receive(:schema).and_return(schema)
  end

  it "fetches the function wrapper from the schema and invokes it" do
    fake_fn = instance_double("FunctionWrapper")
    expect(schema).to receive(:fetch_function).with(:my_func).and_return(fake_fn)
    expect(fake_fn).to receive(:call).with(processor, ctx)
    resolver.value(processor, ctx)
  end

  it "raises an error when the function is not defined in this schema" do
    allow(schema).to receive(:fetch_function).with(:my_func).and_return(nil)
    expect { resolver.value(processor, ctx) }
      .to raise_error(TraitEngine::Error, /undefined function my_func/)
  end
end
