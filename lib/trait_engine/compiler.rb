require "trait_engine/errors"
require "trait_engine/syntax/schema"
require "trait_engine/syntax/declarations"
require "trait_engine/syntax/expressions"
require "trait_engine/syntax/terminal_expressions"
require "trait_engine/method_call_registry"

module TraitEngine
  module CompilationStrategies
    # Base strategy interface that all expression compilers must implement
    class BaseStrategy
      def initialize(compiler)
        @compiler = compiler
      end

      def compile(expr)
        raise NotImplementedError, "Subclasses must implement compile method"
      end

      protected

      attr_reader :compiler

      def compiled_bindings
        compiler.compiled_bindings
      end

      def compile_expression(expr)
        compiler.compile_expression(expr)
      end
    end

    # Strategy for compiling literal values
    class LiteralStrategy < BaseStrategy
      def compile(expr)
        value = expr.value
        ->(ctx) { value }
      end
    end

    # Strategy for compiling field access expressions
    class FieldStrategy < BaseStrategy
      def compile(expr)
        field_name = expr.name
        lambda do |ctx|
          # TODO: make this less ugly :(
          if ctx.is_a?(Hash)
            return ctx[field_name] if ctx.key?(field_name)
            return ctx[field_name.to_sym] if ctx.key?(field_name.to_sym)

            raise Errors::RuntimeError, "Context Hash missing key: '#{field_name}'"
          end

          return ctx.send(field_name.to_sym) if ctx.respond_to?(field_name.to_sym)

          raise Errors::RuntimeError, "Context object does not respond to: '#{field_name}'"
        end
      end
    end

    # Strategy for compiling binding references
    class BindingStrategy < BaseStrategy
      def compile(expr)
        binding_name = expr.name
        lambda do |ctx|
          compiled_fn = compiled_bindings.fetch(binding_name) do
            raise Errors::RuntimeError, "Unresolved binding: #{binding_name}"
          end
          compiled_fn.call(ctx)
        end
      end
    end

    # Strategy for compiling list expressions
    class ListStrategy < BaseStrategy
      def compile(expr)
        element_fns = expr.elements.map { |element| compile_expression(element) }
        lambda do |ctx|
          element_fns.map { |fn| fn.call(ctx) }
        end
      end
    end

    # Strategy for compiling function and operator calls
    class CallStrategy < BaseStrategy
      def compile(expr)
        fn_name = expr.fn_name
        arg_fns = expr.args.map { |arg| compile_expression(arg) }

        lambda do |ctx|
          values = arg_fns.map { |fn| fn.call(ctx) }

          fn_lambda = TraitEngine::MethodCallRegistry.fetch(fn_name)

          fn_lambda.call(*values)
        rescue StandardError => e
          raise Errors::RuntimeError, "Error calling '#{fn_name}': #{e.message}"
        end
      end
    end

    # Strategy for compiling cascade expressions
    class CascadeStrategy < BaseStrategy
      def compile(expr)
        case_fns = expr.cases.map do |when_case|
          cond_fn = compile_expression(when_case.condition)
          result_fn = compile_expression(when_case.result)
          [cond_fn, result_fn]
        end

        lambda do |ctx|
          case_fns.each do |cond_fn, result_fn|
            return result_fn.call(ctx) if cond_fn.call(ctx)
          end
          nil
        end
      end
    end
  end

  class Compiler
    attr_reader :compiled_bindings

    def self.compile(schema)
      new(schema).compile
    end

    def initialize(schema)
      @schema = schema
      @compiled_bindings = {}
      @strategies = build_strategies
    end

    def compile
      compiled_attrs = compile_attributes
      compiled_traits = compile_traits
      compiled_funcs = compile_functions

      @compiled_bindings.merge!(compiled_attrs)
                        .merge!(compiled_traits)
                        .merge!(compiled_funcs)

      ExecutableSchema.new(compiled_attrs, compiled_traits, compiled_funcs)
    end

    def compile_expression(expr)
      strategy = @strategies[expr.class]
      raise Errors::CompilerError, "No compilation strategy for #{expr.class}" unless strategy

      strategy.compile(expr)
    end

    private

    def compile_attributes
      @schema.attributes.map do |attr|
        compiled_fn = compile_expression(attr.expression)
        [attr.name, compiled_fn]
      end.to_h
    end

    def compile_traits
      @schema.traits.map do |trait|
        compiled_fn = compile_expression(trait.expression)
        [trait.name, compiled_fn]
      end.to_h
    end

    def compile_functions
      @schema.functions.map do |func|
        compiled_fn = compile_expression(func.expression)
        [func.name, compiled_fn]
      end.to_h
    end

    def build_strategies
      {
        Syntax::TerminalExpressions::Literal => CompilationStrategies::LiteralStrategy.new(self),
        Syntax::TerminalExpressions::Field => CompilationStrategies::FieldStrategy.new(self),
        Syntax::TerminalExpressions::Binding => CompilationStrategies::BindingStrategy.new(self),
        Syntax::Expressions::ListExpression => CompilationStrategies::ListStrategy.new(self),
        Syntax::Expressions::CallExpression => CompilationStrategies::CallStrategy.new(self),
        Syntax::Expressions::CascadeExpression => CompilationStrategies::CascadeStrategy.new(self)
      }
    end
  end

  class ExecutableSchema
    def initialize(compiled_attrs, compiled_traits, compiled_funcs)
      @compiled_attrs = compiled_attrs
      @compiled_traits = compiled_traits
      @compiled_funcs = compiled_funcs
    end

    def evaluate(data)
      context = prepare_context(data)

      {
        attributes: evaluate_category(@compiled_attrs, context),
        traits: evaluate_category(@compiled_traits, context),
        functions: evaluate_category(@compiled_funcs, context)
      }
    end

    def evaluate_attributes(data)
      context = prepare_context(data)
      evaluate_category(@compiled_attrs, context)
    end

    def evaluate_traits(data)
      context = prepare_context(data)
      evaluate_category(@compiled_traits, context)
    end

    def evaluate_binding(name, data)
      context = prepare_context(data)

      compiled_fn = @compiled_attrs[name] ||
                    @compiled_traits[name] ||
                    @compiled_funcs[name]

      raise Errors::RuntimeError, "No binding found with name: #{name}" unless compiled_fn

      compiled_fn.call(context)
    end

    private

    def prepare_context(data)
      data
    end

    def evaluate_category(compiled_fns, context)
      compiled_fns.map do |name, fn|
        [name, fn.call(context)]
      end.to_h
    rescue StandardError => e
      raise Errors::RuntimeError, "Error during evaluation: #{e.message}"
    end
  end
end
