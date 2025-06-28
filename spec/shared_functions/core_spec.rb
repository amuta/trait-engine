require "trait_engine/shared_functions/core"

RSpec.describe TraitEngine::SharedFunctions do
  let(:fns) { described_class::REGISTRY }

  it "includes :concatenate and joins strings" do
    expect(fns).to have_key(:concatenate)
    expect(fns[:concatenate].call("a", "b", "c")).to eq("abc")
  end

  it "includes :upcase and uppercases input" do
    expect(fns[:upcase].call("Hello")).to eq("HELLO")
  end

  it "includes :downcase and lowercases input" do
    expect(fns[:downcase].call("Hello")).to eq("hello")
  end

  it "includes :remove_spaces and strips spaces" do
    expect(fns[:remove_spaces].call("a b c")).to eq("abc")
  end

  it "includes :length and returns string length" do
    expect(fns[:length].call("foobar")).to eq(6)
  end

  it "no further registrations are allowed when freezed" do
    described_class.freeze
    expect { described_class.register(:foo) {} }
      .to raise_error(TraitEngine::RegistryFrozenError)
  end
end
