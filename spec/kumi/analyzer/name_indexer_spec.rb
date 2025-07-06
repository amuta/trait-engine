RSpec.describe Kumi::Analyzer::Passes::NameIndexer do
  include Kumi::ASTFactory

  # compact location literal
  def loc(off = 0) = syntax(:location, __FILE__, __LINE__ + off, 0)

  # quick builders
  def attr_node(name)  = syntax(:attribute, name, syntax(:literal, 1, loc: loc), loc: loc)
  def trait_node(name) = syntax(:trait, name, syntax(:call_expression, :noop, loc: loc), loc: loc)

  describe ".run" do
    context "when the schema is empty" do
      let(:schema) { syntax(:schema, [], [], loc: loc) }

      it "leaves the state empty and records no errors" do
        state = {}
        errors = []
        described_class.new(schema, state).run(errors)

        expect(state[:definitions]).to eq({})
        expect(errors).to be_empty
      end
    end

    context "with unique attribute and trait names" do
      let(:schema) { syntax(:schema, [attr_node(:price)], [trait_node(:vip)], loc: loc) }

      it "stores each declaration and reports zero errors" do
        state = {}
        errors = []
        described_class.new(schema, state).run(errors)

        expect(errors).to be_empty
        expect(state[:definitions].keys).to contain_exactly(:price, :vip)
        expect(state[:definitions][:price]).to be_a(Kumi::Syntax::Declarations::Attribute)
        expect(state[:definitions][:vip]).to be_a(Kumi::Syntax::Declarations::Trait)
      end
    end

    context "when duplicate names appear" do
      let(:schema) { syntax(:schema, [attr_node(:dup), attr_node(:dup)], [], loc: loc) }

      it "records a single duplicate-definition error" do
        state = {}
        errors = []
        described_class.new(schema, state).run(errors)

        expect(errors.size).to eq(1)
        expect(errors.first.last).to match(/duplicated definition `dup`/)
      end
    end

    context "when an attribute and a trait share the same name" do
      let(:schema) { syntax(:schema, [attr_node(:conflict)], [trait_node(:conflict)], loc: loc) }

      it "registers the duplicate and keeps the last declaration in the map" do
        state = {}
        errors = []
        described_class.new(schema, state).run(errors)

        expect(errors.size).to eq(1)
        expect(state[:definitions][:conflict]).to be_a(Kumi::Syntax::Declarations::Trait)
      end
    end

    context "case-sensitive symbols" do
      let(:schema) { syntax(:schema, [attr_node(:Camel)], [trait_node(:camel)], loc: loc) }

      it "treats differently cased symbols as distinct names" do
        state = {}
        errors = []
        described_class.new(schema, state).run(errors)

        expect(errors).to be_empty
        expect(state[:definitions].keys).to contain_exactly(:Camel, :camel)
      end
    end
  end
end
