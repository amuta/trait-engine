RSpec.describe TraitEngine::Resolvers::Field do
  let(:field) { described_class.new(:tier) }

  it "pulls value from context hash" do
    expect(field.value(nil, { tier: "gold" })).to eq("gold")
  end

  it "descriptor shows key" do
    expect(field.descriptor).to eq("field:tier")
  end
end
