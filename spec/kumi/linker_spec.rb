require "spec_helper"
require "kumi/parser/dsl"
require "kumi/linker"
require "kumi/errors"

RSpec.describe Kumi::Linker do
  let(:dsl) { Kumi::Parser::Dsl }

  before do
    unless Kumi::MethodCallRegistry.supported?(:hello)
      hello_fn_lambda = ->(name) { "Hello, #{name}!" }
      Kumi::MethodCallRegistry.register(:hello, hello_fn_lambda, arity: 1, types: [:any])
    end
  end

  describe ".link!" do
    context "with a valid schema" do
      it "returns the schema unchanged" do
        schema = dsl.schema do
          attribute :name, key(:first_name)
          trait     :adult,  key(:age), :>=, 18
          attribute :list,   [literal(1), literal(2)]
        end

        expect { described_class.link!(schema) }.not_to raise_error
        expect(described_class.link!(schema)).to be(schema)
      end

      it "saves leaf nodes " do
        schema = dsl.schema do
          attribute :name2, ref(:name)
          attribute :name, ref(:list2)
          trait     :adult,  key(:age), :>=, 18
          attribute :list,   [literal(1), literal(2), key(:my_name)]
          attribute :list2 do
            on_trait :adult, ref(:list)
            default literal("default")
          end
        end

        described_class.link!(schema)
      end
    end

    context "duplicate definitions" do
      it "raises for two attributes with the same name" do
        schema = dsl.schema do
          attribute :foo, literal(1)
          attribute :foo, literal(2)
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /duplicate definition of `foo`/)
      end

      it "raises for two traits with the same name" do
        schema = dsl.schema do
          trait :t1, key(:x), :==, 1
          trait :t1, key(:y), :==, 2
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /duplicate definition of `t1`/)
      end

      it "raises for two attributes with the same name" do
        schema = dsl.schema do
          attribute :f1, fn(:foo, literal(1))
          attribute :f1, fn(:foo, literal(2))
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /duplicate definition of `f1`/)
      end

      it "raises when an attribute and a trait share the same name" do
        schema = dsl.schema do
          attribute :name, "x"
          trait     :name, key(:name), :==, "x"
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /duplicate definition of `name`/)
      end
    end

    context "undefined references" do
      it "raises when an attribute binding refers to a missing name" do
        schema = dsl.schema do
          attribute :foo, ref(:bar)
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /undefined reference to `bar`/)
      end

      it "raises for a cascade that references an undefined trait" do
        schema = dsl.schema do
          attribute :status do
            on_trait :unknown_trait, literal("x")
          end
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /undefined reference to `unknown_trait`/)
      end

      it "raises when a trait's expression binds to an undefined name" do
        schema = dsl.schema do
          trait :t2, ref(:missing), :==, literal(0)
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /undefined reference to `missing`/)
      end

      it "raises when a attribute's argument binds to an undefined name" do
        schema = dsl.schema do
          attribute :f2, fn(:hello, ref(:baz))
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /undefined reference to `baz`/)
      end

      it "raises when a list expression contains an undefined binding" do
        schema = dsl.schema do
          attribute :arr, [ref(:x), literal(2)]
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /undefined reference to `x`/)
      end
    end

    context "cycle detection" do
      it "raises for a direct mutual cycle" do
        schema = dsl.schema do
          attribute :a, ref(:b)
          attribute :b, ref(:a)
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /cycle detected: a → b → a/)
      end

      it "raises for a self-cycle (a → a)" do
        schema = dsl.schema do
          attribute :a, ref(:a)
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /cycle detected: a → a/)
      end

      it "raises for a longer indirect cycle" do
        schema = dsl.schema do
          attribute :a, ref(:b)
          attribute :b, ref(:c)
          attribute :c, ref(:a)
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /cycle detected: a → b → c → a/)
      end

      it "does not raise for an acyclic binding graph" do
        schema = dsl.schema do
          attribute :x, literal(1)
          attribute :y, ref(:x)
          attribute :z, literal(2)
        end

        expect do
          described_class.link!(schema)
        end.not_to raise_error
      end
    end

    context "cascade validation" do
      it "allows a cascade on a defined trait" do
        schema = dsl.schema do
          trait :t1, key(:flag), :==, true

          attribute :status do
            on_trait :t1, literal("ok")
          end
        end

        expect do
          described_class.link!(schema)
        end.not_to raise_error
      end
    end
    context "operator reference" do
      it "raises if a trait uses an unknown operator (DSL check skipped)" do
        # this allow is to avoid the parser breaking before the linker
        allow(Kumi::MethodCallRegistry)
          .to receive(:operator?)
          .and_return(true)

        schema = dsl.schema do
          trait :t1, key(:value), :bogus_op, 42
        end

        expect do
          described_class.link!(schema)
        end.to raise_error(Kumi::Errors::SemanticError,
                           /unsupported operator `bogus_op`/)
      end
    end
  end
  context "operator arity validation" do
    it "raises SemanticError when trait uses operator with wrong arity" do
      # pretend :>= is supported but wrong-arity
      schema = dsl.schema do
        trait :check, key(:age), :>=, 18 # this is fine
      end

      # now mutate the AST to have 3 args:
      schema.traits.first.expression.args << Kumi::Syntax::TerminalExpressions::Literal.new(30)

      expect do
        described_class.link!(schema)
      end.to raise_error(Kumi::Errors::SemanticError,
                         /operator `>=` expects 2 arguments, got 3/)
    end

    it "raises SemanticError for an unknown operator" do
      # this allow is to avoid the parser breaking before the linker
      allow(Kumi::MethodCallRegistry)
        .to receive(:operator?)
        .and_return(true)

      schema = dsl.schema do
        trait :t1, key(:x), :bogus_op, literal(1)
      end

      expect do
        described_class.link!(schema)
      end.to raise_error(Kumi::Errors::SemanticError,
                         /unsupported operator `bogus_op`/)
    end

    it "allows correct-arity, supported operator" do
      allow(Kumi::MethodCallRegistry)
        .to receive(:signature)
        .with(:>=).and_return({ arity: 2 })

      schema = dsl.schema do
        trait :adult, key(:age), :>=, 18
      end

      expect { described_class.link!(schema) }.not_to raise_error
    end
  end
end
