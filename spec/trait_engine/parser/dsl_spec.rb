require "spec_helper"
require "trait_engine/parser/dsl"

RSpec.describe TraitEngine::Parser::Dsl do
  def build_schema(&block)
    subject.schema(&block)
  end

  describe ".schema" do
    let(:subject) { described_class }
    it "can define attributes" do
      schema = build_schema do
        attribute :name, field(:first_name)
      end

      expect(schema.attributes.size).to eq(1)
      expect(schema.attributes.first).to be_a(TraitEngine::Syntax::Declarations::Attribute)
      expect(schema.attributes.first.name).to eq(:name)
      expect(schema.attributes.first.expression).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
      expect(schema.attributes.first.expression.name).to eq(:first_name)
    end

    it "can define traits" do
      schema = build_schema do
        trait :vip, field(:status), :==, literal("VIP")
      end

      expect(schema.traits.size).to eq(1)
      trait = schema.traits.first
      expect(trait).to be_a(TraitEngine::Syntax::Declarations::Trait)
      expect(trait.name).to eq(:vip)
      expect(trait.expression).to be_a(TraitEngine::Syntax::Expressions::CallExpression)
      expect(trait.expression.fn_name).to eq(:==)
      expect(trait.expression.args.size).to eq(2)
      expect(trait.expression.args.first).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
      expect(trait.expression.args.last).to be_a(TraitEngine::Syntax::TerminalExpressions::Literal)
    end

    it "can define functions" do
      schema = build_schema do
        function :calculate_discount, call(:discount, field(:amount))
      end

      expect(schema.functions.size).to eq(1)
      function = schema.functions.first
      expect(function).to be_a(TraitEngine::Syntax::Declarations::Function)
      expect(function.name).to eq(:calculate_discount)
      expect(function.expression).to be_a(TraitEngine::Syntax::Expressions::CallExpression)
      expect(function.expression.fn_name).to eq(:discount)
      expect(function.expression.args.size).to eq(1)
      expect(function.expression.args.first).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
    end

    it "can define multiple attributes, traits, and functions" do
      schema = build_schema do
        attribute :name, field(:first_name)
        attribute :age, field(:birth_date)

        trait :adult, field(:age), :>=, 18
        trait :senior, field(:age), :>=, 65

        function :greet, call(:hello, field(:name))
      end

      expect(schema.attributes.size).to eq(2)
      expect(schema.traits.size).to eq(2)
      expect(schema.functions.size).to eq(1)

      expect(schema.attributes.map(&:name)).to contain_exactly(:name, :age)
      expect(schema.traits.map(&:name)).to contain_exactly(:adult, :senior)
      expect(schema.functions.map(&:name)).to contain_exactly(:greet)

      expect(schema.attributes.map { |attr| attr.expression.name }).to contain_exactly(:first_name, :birth_date)
      expect(schema.attributes.map { |attr| attr.expression }).to all(be_a(TraitEngine::Syntax::TerminalExpressions::Field))

      expect(schema.traits.map(&:expression)).to all(be_a(TraitEngine::Syntax::Expressions::CallExpression))
      expect(schema.traits.map(&:expression).map(&:fn_name)).to contain_exactly(:>=, :>=)
      expect(schema.traits.map(&:expression).flat_map(&:args).to_set).to contain_exactly(
        be_a(TraitEngine::Syntax::TerminalExpressions::Field),
        be_a(TraitEngine::Syntax::TerminalExpressions::Literal),
        be_a(TraitEngine::Syntax::TerminalExpressions::Literal)
      )

      expect(schema.functions.map(&:expression)).to all(be_a(TraitEngine::Syntax::Expressions::CallExpression))
      expect(schema.functions.map(&:expression).map(&:fn_name)).to contain_exactly(:hello)
      expect(schema.functions.map(&:expression).flat_map(&:args)).to all(be_a(TraitEngine::Syntax::TerminalExpressions::Field))
      expect(schema.functions.map(&:expression).flat_map(&:args).map(&:name)).to contain_exactly(:name)
    end
  end

  describe "schema validation" do
    let(:error_class) { TraitEngine::Errors::SyntaxError }

    context "when defining names" do
      it "raises an error if an attribute name is not a symbol" do
        expect do
          build_schema do
            attribute "name_string", field(:first_name)
          end
        end.to raise_error(error_class, /The name for 'attribute' must be a Symbol, got String/)
      end

      it "raises an error if a trait name is not a symbol" do
        expect do
          build_schema do
            trait "not_a_symbol", field(:age), :<, 18
          end
        end.to raise_error(error_class, /The name for 'trait' must be a Symbol, got String/)
      end

      it "raises an error if a function name is not a symbol" do
        expect do
          build_schema do
            function "not_a_symbol", call(:foo)
          end
        end.to raise_error(error_class, /The name for 'function' must be a Symbol, got String/)
      end
    end

    context "when defining attributes" do
      it "raises an error if an attribute has no expression or block" do
        expect do
          build_schema do
            attribute :name
          end
        end.to raise_error(error_class, /attribute 'name' requires an expression or a block/)
      end

      it "raises an error for an invalid expression type" do
        expect do
          build_schema do
            attribute :name, { some: :hash }
          end
        end.to raise_error(error_class, /Invalid expression/)
      end
    end

    context "when defining traits" do
      it "raises an error if the operator is not a symbol" do
        expect do
          build_schema do
            trait :is_minor, field(:age), "not_a_symbol", 18
          end
        end.to raise_error(error_class, /expects a symbol for an operator, got String/)
      end

      it "raises an error if the operator is not supported" do
        expect do
          build_schema do
            trait :unsupported, field(:value), :>>, 42
          end
        end.to raise_error(error_class, /unsupported operator `>>`/)
      end

      it "raises an error if a trait has an invalid expression size" do
        expect do
          build_schema do
            trait :invalid_trait, field(:value), :==
          end
        end.to raise_error(error_class, /trait 'invalid_trait' requires exactly 3 arguments: lhs, operator, and rhs/)
      end
    end

    context "when defining functions" do
      it "raises an error if the expression is not a call" do
        expect do
          build_schema do
            function :my_func, ref(:some_other_func)
          end
        end.to raise_error(error_class, /must be defined with a `call\(\.\.\.\)`/)
      end
    end

    context "when using invalid expressions" do
      it "raises an error for unknown expression types in a call" do
        expect do
          build_schema do
            function :my_func, call(:foo, self)
          end
        end.to raise_error(error_class, /Invalid expression/)
      end

      it "raises an error for unsupported operators" do
        expect do
          build_schema do
            trait :unsupported, field(:value), :>>, 42
          end
        end.to raise_error(error_class, /unsupported operator `>>`/)
      end
    end
  end

  context "Class extension" do
    let(:klass) { Class.new { extend TraitEngine::Parser::Dsl } }

    it "adds a `schema` method to classes that extend the DSL" do
      expect(klass).to respond_to(:schema)
    end

    it "builds a Syntax::Schema populated by attributes, traits, and functions" do
      schema = klass.schema do
        attribute :name, field(:first_name)
        trait     :adult, field(:age), :>=, 18
        function  :greet, call(:hello, field(:name))
      end

      expect(schema).to be_a(TraitEngine::Syntax::Schema)
      expect(schema.attributes.map(&:name)).to    contain_exactly(:name)
      expect(schema.traits.map(&:name)).to        contain_exactly(:adult)
      expect(schema.functions.map(&:name)).to     contain_exactly(:greet)

      # Spot‐check internals
      expect(schema.attributes.first.expression.name).to eq(:first_name)
      expect(schema.traits.first.expression.fn_name).to     eq(:>=)
      expect(schema.functions.first.expression.fn_name).to  eq(:hello)
    end

    describe "error propagation from within a class" do
      let(:fixture_path) { File.expand_path("../../fixtures/invalid_schema_class.rb", __dir__) }
      let(:line)         { 8 }

      it "raises a SyntaxError pointing at the fixture file and line" do
        expect { load fixture_path }.to raise_error(TraitEngine::Errors::SyntaxError) { |error|
          expect(error.message).to match(
            /invalid_schema_class\.rb:#{line}: attribute 'name' requires an expression or a block/
          )
        }
      end
    end
  end

  context "syntax validations" do
    context "attribute" do
      it "accepts <symbol>, <expression>" do
        schema = build_schema do
          attribute :name, field(:first_name)
        end

        expect(schema.attributes.size).to eq(1)
        expect(schema.attributes.first.name).to eq(:name)
        expect(schema.attributes.first.expression).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
      end

      it "accepts <symbol> with a block" do
        schema = build_schema do
          attribute :status do
            on_trait :active, field(:active)
          end
        end

        expect(schema.attributes.size).to eq(1)
        expect(schema.attributes.first.expression).to be_a(TraitEngine::Syntax::Expressions::CascadeExpression)
        expect(schema.attributes.first.expression.cases.size).to eq(1)
        cases = schema.attributes.first.expression.cases
        expect(cases.size).to eq(1)
        expect(cases.first).to be_a(TraitEngine::Syntax::Expressions::WhenCaseExpression)
        expect(cases.first.condition).to be_a(TraitEngine::Syntax::Expressions::CallExpression)
        expect(cases.first.condition.fn_name).to eq(:all?)
        expect(cases.first.condition.args.size).to eq(1)
        expect(cases.first.condition.args.first).to be_a(TraitEngine::Syntax::Expressions::ListExpression)
        expect(cases.first.condition.args.first.elements.size).to eq(1)
        expect(cases.first.condition.args.first.elements.first).to be_a(TraitEngine::Syntax::TerminalExpressions::Binding)
        expect(cases.first.condition.args.first.elements.first.name).to eq(:active)
        expect(cases.first.result).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
        expect(cases.first.result.name).to eq(:active)
      end

      context "cascade cases" do
        let(:schema) do
          build_schema do
            attribute :status do
              on_trait :active, field(:active)
              on_traits :verified, field(:verified)
              default field(:default_status)
            end
          end
        end
        let(:attribute_expr) { schema.attributes.first.expression }
        let(:first_case) { attribute_expr.cases[0] }
        let(:second_case) { attribute_expr.cases[1] }
        let(:default_case) { attribute_expr.cases[2] }

        it "creates a cascade expression with cases: whencases" do
          expect(attribute_expr).to be_a(TraitEngine::Syntax::Expressions::CascadeExpression)
          expect(attribute_expr.cases.size).to eq(3)
        end

        it "creates the first case with a condition and result" do
          expect(first_case.condition).to be_a(TraitEngine::Syntax::Expressions::CallExpression)
          expect(first_case.condition.fn_name).to eq(:all?)
          expect(first_case.condition.args.size).to eq(1)
          expect(first_case.condition.args.first).to be_a(TraitEngine::Syntax::Expressions::ListExpression)
          expect(first_case.condition.args.first.elements.size).to eq(1)
          expect(first_case.condition.args.first.elements.first).to be_a(TraitEngine::Syntax::TerminalExpressions::Binding)
          expect(first_case.condition.args.first.elements.first.name).to eq(:active)
          expect(first_case.result).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
          expect(first_case.result.name).to eq(:active)
        end

        it "creates the second case with a condition and result" do
          expect(second_case.condition).to be_a(TraitEngine::Syntax::Expressions::CallExpression)
          expect(second_case.condition.fn_name).to eq(:all?)
          expect(second_case.condition.args.size).to eq(1)
          expect(second_case.condition.args.first).to be_a(TraitEngine::Syntax::Expressions::ListExpression)
          expect(second_case.condition.args.first.elements.size).to eq(1)
          expect(second_case.condition.args.first.elements.first).to be_a(TraitEngine::Syntax::TerminalExpressions::Binding)
          expect(second_case.condition.args.first.elements.first.name).to eq(:verified)
          expect(second_case.result).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
          expect(second_case.result.name).to eq(:verified)
        end

        it "creates the default case with a condition and result" do
          expect(default_case.condition).to be_a(TraitEngine::Syntax::TerminalExpressions::Literal)
          expect(default_case.condition.value).to eq(true) # Always matches
          expect(default_case.result).to be_a(TraitEngine::Syntax::TerminalExpressions::Field)
          expect(default_case.result.name).to eq(:default_status)
        end
      end
    end
  end
end
