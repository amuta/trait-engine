RSpec.describe Kumi::Analyzer::Passes::TypeValidator do
  include Kumi::ASTFactory

  before do
    # Stub Kumi::MethodCallRegistry with predictable behaviour
    allow(Kumi::MethodCallRegistry).to receive(:confirm_support!).and_return(true)
    allow(Kumi::MethodCallRegistry).to receive(:signature).and_return({ arity: 1 })
  end

  let(:state)  { {} }
  let(:errors) { [] }

  def run(schema)
    # First pass: NameIndexer to populate :definitions
    Kumi::Analyzer::Passes::NameIndexer.new(schema, state).run(errors)
    # Second pass: TypeValidator
    described_class.new(schema, state).run(errors)
  end

  describe ".run" do
    context "valid schema" do
      let(:schema) do
        price = attr(:price)
        high  = trait(:high_price, call(:gt, binding_ref(:price)))
        syntax(:schema, [price], [high], loc: loc)
      end

      it "adds dependency and leaf info without errors" do
        run(schema)

        expect(errors).to be_empty
        expect(state[:dependency_graph][:high_price]).to eq(Set[:price])
        expect(state[:leaf_map][:price].first.value).to eq(1)
      end
    end

    context "undefined binding reference" do
      let(:schema) do
        bad_trait = trait(:oops, call(:eq, binding_ref(:missing)))
        syntax(:schema, [], [bad_trait], loc: loc)
      end

      it "records an undefined-reference error" do
        run(schema)

        expect(errors.first.last).to match(/undefined reference to `missing`/)
      end
    end

    context "attribute without expression" do
      let(:schema) { syntax(:schema, [syntax(:attribute, :broken, nil, loc: loc)], [], loc: loc) }

      it "adds an attribute-expression error" do
        run(schema)

        expect(errors.first.last).to match(/requires an expression/)
      end
    end

    context "trait not wrapping CallExpression" do
      let(:schema) do
        bad_trait = trait(:flag, syntax(:literal, true, loc: loc))
        syntax(:schema, [], [bad_trait], loc: loc)
      end

      it "reports a trait-predicate error" do
        run(schema)

        expect(errors.first.last).to match(/must wrap a CallExpression/)
      end
    end

    context "operator arity mismatch" do
      before { allow(Kumi::MethodCallRegistry).to receive(:signature).and_return({ arity: 2 }) }

      let(:schema) do
        bad = trait(:bad, call(:gt, syntax(:literal, 1, loc: loc)))
        syntax(:schema, [], [bad], loc: loc)
      end

      it "records an arity error" do
        run(schema)

        expect(errors.first.last).to match(/expects 2 args, got 1/)
      end
    end
  end
end
