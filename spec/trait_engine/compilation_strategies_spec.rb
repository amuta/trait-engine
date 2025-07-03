require "spec_helper"
require "trait_engine/compiler"

RSpec.describe TraitEngine::CompilationStrategies do
  # Mock compiler to provide necessary interface for strategy testing
  let(:mock_compiler) do
    Class.new do
      attr_accessor :compiled_bindings

      def initialize
        @compiled_bindings = {}
      end

      def compile_expression(expr)
        # Simple mock implementation for recursive compilation
        case expr
        when TraitEngine::Syntax::TerminalExpressions::Literal
          ->(ctx) { expr.value }
        else
          ->(ctx) { "mocked_#{expr.class.name}" }
        end
      end
    end.new
  end

  describe TraitEngine::CompilationStrategies::LiteralStrategy do
    subject { described_class.new(mock_compiler) }

    it "compiles literal values into constant methods" do
      literal_expr = TraitEngine::Syntax::TerminalExpressions::Literal.new(42)
      compiled_fn = subject.compile(literal_expr)

      expect(compiled_fn.call({})).to eq(42)
      expect(compiled_fn.call({ some: :context })).to eq(42)
    end

    it "handles different literal types correctly" do
      string_literal = TraitEngine::Syntax::TerminalExpressions::Literal.new("hello")
      boolean_literal = TraitEngine::Syntax::TerminalExpressions::Literal.new(true)
      nil_literal = TraitEngine::Syntax::TerminalExpressions::Literal.new(nil)

      expect(subject.compile(string_literal).call({})).to eq("hello")
      expect(subject.compile(boolean_literal).call({})).to be true
      expect(subject.compile(nil_literal).call({})).to be_nil
    end
  end

  describe TraitEngine::CompilationStrategies::FieldStrategy do
    subject { described_class.new(mock_compiler) }

    it "compiles field access for hash contexts" do
      field_expr = TraitEngine::Syntax::TerminalExpressions::Field.new(:name)
      compiled_fn = subject.compile(field_expr)

      context = { name: "Alice", age: 30 }
      expect(compiled_fn.call(context)).to eq("Alice")
    end

    it "compiles fields access for hash contex with string keys" do
      field_expr = TraitEngine::Syntax::TerminalExpressions::Field.new("name")
      compiled_fn = subject.compile(field_expr)

      context = { "name" => "Bob", "age" => 25 }
      expect(compiled_fn.call(context)).to eq("Bob")
    end

    it "raises error for missing fields when contexti is a Hash" do
      field_expr = TraitEngine::Syntax::TerminalExpressions::Field.new(:missing_field)
      compiled_fn = subject.compile(field_expr)

      context = { name: "Alice" }

      expect do
        compiled_fn.call(context)
      end.to raise_error(TraitEngine::Errors::RuntimeError,
                         /Context Hash missing key: 'missing_field'/)
    end

    it "raises error for unsupported context types" do
      field_expr = TraitEngine::Syntax::TerminalExpressions::Field.new(:name)
      compiled_fn = subject.compile(field_expr)

      unsupported_context = "string context"
      expect do
        compiled_fn.call(unsupported_context)
      end.to raise_error(TraitEngine::Errors::RuntimeError,
                         /Context object does not respond to: 'name'/)
    end
  end

  describe TraitEngine::CompilationStrategies::BindingStrategy do
    subject { described_class.new(mock_compiler) }

    it "compiles binding references that resolve at runtime" do
      binding_expr = TraitEngine::Syntax::TerminalExpressions::Binding.new(:other_value)
      compiled_fn = subject.compile(binding_expr)

      # Set up the compiled bindings after compilation
      mock_compiler.compiled_bindings[:other_value] = ->(ctx) { ctx[:multiplier] * 10 }

      context = { multiplier: 5 }
      expect(compiled_fn.call(context)).to eq(50)
    end

    it "raises error for unresolved bindings" do
      binding_expr = TraitEngine::Syntax::TerminalExpressions::Binding.new(:missing_binding)
      compiled_fn = subject.compile(binding_expr)

      expect do
        compiled_fn.call({})
      end.to raise_error(TraitEngine::Errors::RuntimeError, /Unresolved binding: missing_binding/)
    end

    it "supports nested binding resolution" do
      binding_expr = TraitEngine::Syntax::TerminalExpressions::Binding.new(:nested_ref)
      compiled_fn = subject.compile(binding_expr)

      # Set up a chain of bindings
      mock_compiler.compiled_bindings[:nested_ref] = lambda { |ctx|
        mock_compiler.compiled_bindings[:base_value].call(ctx) + 1
      }
      mock_compiler.compiled_bindings[:base_value] = ->(ctx) { ctx[:base] }

      context = { base: 10 }
      expect(compiled_fn.call(context)).to eq(11)
    end
  end

  describe TraitEngine::CompilationStrategies::ListStrategy do
    subject { described_class.new(mock_compiler) }

    it "compiles list expressions into array-producing methods" do
      elements = [
        TraitEngine::Syntax::TerminalExpressions::Literal.new(1),
        TraitEngine::Syntax::TerminalExpressions::Literal.new(2),
        TraitEngine::Syntax::TerminalExpressions::Literal.new(3)
      ]
      list_expr = TraitEngine::Syntax::Expressions::ListExpression.new(elements)
      compiled_fn = subject.compile(list_expr)

      expect(compiled_fn.call({})).to eq([1, 2, 3])
    end

    it "handles empty lists correctly" do
      list_expr = TraitEngine::Syntax::Expressions::ListExpression.new([])
      compiled_fn = subject.compile(list_expr)

      expect(compiled_fn.call({})).to eq([])
    end

    it "evaluates each element in the context" do
      # Create a more sophisticated mock compiler for this test
      sophisticated_compiler = Class.new do
        attr_accessor :compiled_bindings

        def initialize
          @compiled_bindings = {}
        end

        def compile_expression(expr)
          case expr
          when TraitEngine::Syntax::TerminalExpressions::Literal
            ->(ctx) { expr.value }
          when TraitEngine::Syntax::TerminalExpressions::Field
            field_name = expr.name
            ->(ctx) { ctx[field_name] }
          end
        end
      end.new

      strategy = described_class.new(sophisticated_compiler)

      elements = [
        TraitEngine::Syntax::TerminalExpressions::Literal.new("static"),
        TraitEngine::Syntax::TerminalExpressions::Field.new(:dynamic)
      ]
      list_expr = TraitEngine::Syntax::Expressions::ListExpression.new(elements)
      compiled_fn = strategy.compile(list_expr)

      context = { dynamic: "context_value" }
      expect(compiled_fn.call(context)).to eq(%w[static context_value])
    end
  end

  describe TraitEngine::CompilationStrategies::CallStrategy do
    subject { described_class.new(mock_compiler) }

    before do
      custom_func_lambda = ->(a, b) { "custom_#{a}_#{b}" }
      unless TraitEngine::MethodCallRegistry.supported?(:custom_func)
        TraitEngine::MethodCallRegistry.register(:custom_func, custom_func_lambda, arity: 2, types: %i[any any])
      end

      error_func_lambda = -> { raise StandardError, "Something went wrong" }
      unless TraitEngine::MethodCallRegistry.supported?(:error_func)
        TraitEngine::MethodCallRegistry.register(:error_func, error_func_lambda, arity: 0, types: [])
      end
    end

    it "compiles method calls using the method registry" do
      args = [
        TraitEngine::Syntax::TerminalExpressions::Literal.new(5),
        TraitEngine::Syntax::TerminalExpressions::Literal.new(5)
      ]
      call_expr = TraitEngine::Syntax::Expressions::CallExpression.new(:==, args)
      compiled_fn = subject.compile(call_expr)

      expect(compiled_fn.call({})).to eq(true)
    end

    it "compiles custom method calls using the method registry" do
      args = [
        TraitEngine::Syntax::TerminalExpressions::Literal.new("hello"),
        TraitEngine::Syntax::TerminalExpressions::Literal.new("world")
      ]
      call_expr = TraitEngine::Syntax::Expressions::CallExpression.new(:custom_func, args)
      compiled_fn = subject.compile(call_expr)

      expect(compiled_fn.call({})).to eq("custom_hello_world")
    end

    it "handles runtime errors in method calls gracefully" do
      call_expr = TraitEngine::Syntax::Expressions::CallExpression.new(:error_func, [])
      compiled_fn = subject.compile(call_expr)

      expect { compiled_fn.call({}) }.to raise_error(TraitEngine::Errors::RuntimeError, /Error calling 'error_func'/)
    end
  end

  describe TraitEngine::CompilationStrategies::CascadeStrategy do
    subject { described_class.new(mock_compiler) }

    let(:when_case_true) do
      TraitEngine::Syntax::Expressions::WhenCaseExpression.new(
        TraitEngine::Syntax::TerminalExpressions::Literal.new(true),
        TraitEngine::Syntax::TerminalExpressions::Literal.new("matched_true")
      )
    end

    let(:when_case_false) do
      TraitEngine::Syntax::Expressions::WhenCaseExpression.new(
        TraitEngine::Syntax::TerminalExpressions::Literal.new(false),
        TraitEngine::Syntax::TerminalExpressions::Literal.new("matched_false")
      )
    end

    it "compiles cascades that evaluate conditions in order" do
      cascade_expr = TraitEngine::Syntax::Expressions::CascadeExpression.new([when_case_true, when_case_false])
      compiled_fn = subject.compile(cascade_expr)

      expect(compiled_fn.call({})).to eq("matched_true")
    end

    it "continues evaluation until a condition matches" do
      cascade_expr = TraitEngine::Syntax::Expressions::CascadeExpression.new([when_case_false, when_case_true])
      compiled_fn = subject.compile(cascade_expr)

      expect(compiled_fn.call({})).to eq("matched_true")
    end

    it "returns nil when no conditions match" do
      cascade_expr = TraitEngine::Syntax::Expressions::CascadeExpression.new([when_case_false])
      compiled_fn = subject.compile(cascade_expr)

      expect(compiled_fn.call({})).to be_nil
    end

    it "handles complex conditional expressions" do
      # Create a more sophisticated mock for complex expressions
      complex_compiler = Class.new do
        attr_accessor :compiled_bindings

        def initialize
          @compiled_bindings = {}
        end

        def compile_expression(expr)
          case expr
          when TraitEngine::Syntax::TerminalExpressions::Literal
            ->(ctx) { expr.value }
          when TraitEngine::Syntax::TerminalExpressions::Field
            field_name = expr.name
            ->(ctx) { ctx[field_name] }
          end
        end
      end.new

      strategy = described_class.new(complex_compiler)

      conditional_case = TraitEngine::Syntax::Expressions::WhenCaseExpression.new(
        TraitEngine::Syntax::TerminalExpressions::Field.new(:should_match),
        TraitEngine::Syntax::TerminalExpressions::Literal.new("condition_met")
      )

      cascade_expr = TraitEngine::Syntax::Expressions::CascadeExpression.new([conditional_case])
      compiled_fn = strategy.compile(cascade_expr)

      expect(compiled_fn.call({ should_match: true })).to eq("condition_met")
      expect(compiled_fn.call({ should_match: false })).to be_nil
    end
  end

  describe "Strategy Integration" do
    it "allows strategies to be tested independently" do
      # Each strategy can be instantiated and tested without a full compiler
      literal_strategy = TraitEngine::CompilationStrategies::LiteralStrategy.new(mock_compiler)
      field_strategy = TraitEngine::CompilationStrategies::FieldStrategy.new(mock_compiler)

      literal_expr = TraitEngine::Syntax::TerminalExpressions::Literal.new("test")
      field_expr = TraitEngine::Syntax::TerminalExpressions::Field.new(:name)

      literal_fn = literal_strategy.compile(literal_expr)
      field_fn = field_strategy.compile(field_expr)

      context = { name: "integration_test" }

      expect(literal_fn.call(context)).to eq("test")
      expect(field_fn.call(context)).to eq("integration_test")
    end

    it "supports extending the compiler with new strategies" do
      # Demonstrate how new expression types can be added without modifying existing code
      new_strategy_class = Class.new(TraitEngine::CompilationStrategies::BaseStrategy) do
        def compile(expr)
          # Mock implementation for a hypothetical new expression type
          ->(ctx) { "custom_strategy_result" }
        end
      end

      custom_strategy = new_strategy_class.new(mock_compiler)
      mock_expr = double("CustomExpression")

      compiled_fn = custom_strategy.compile(mock_expr)
      expect(compiled_fn.call({})).to eq("custom_strategy_result")
    end
  end
end
