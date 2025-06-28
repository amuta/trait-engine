# frozen_string_literal: true

require "trait_engine"

RSpec.describe TraitEngine::Registry do
  after { described_class.reset_for_reload! }

  it "registers and fetches a function" do
    described_class.register(:up) { |v| v.upcase }
    fn = described_class.fetch(:up)
    expect(fn.call("hi")).to eq("HI")
  end

  it "raises UnknownFunctionError for missing key" do
    expect { described_class.fetch(:nope) }
      .to raise_error(TraitEngine::UnknownFunctionError)
  end

  it "freezes and prevents further registration" do
    described_class.freeze_registry!
    expect { described_class.register(:nada) { nil } }
      .to raise_error(TraitEngine::Error, /Registry frozen/)
  end
end
