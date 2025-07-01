require_relative "../syntax/declarations"
require_relative "../syntax/expressions"
require_relative "../syntax/terminal_expressions"
require_relative "../syntax/node"
require "trait_engine/errors"
require "trait_engine/operator_registry"
require_relative "dsl_cascade_builder"

module TraitEngine
  module Parser
    class DslBuilderContext
      attr_accessor :last_loc
      attr_reader :attributes, :traits, :functions

      include Syntax::Declarations
      include Syntax::Expressions
      include Syntax::TerminalExpressions

      def initialize
        @attributes = []
        @traits     = []
        @functions  = []
      end

      def attribute(name, expr = nil, &blk)
        loc = current_location
        validate_name(name, :attribute, loc)

        has_expr = !expr.nil?
        has_block = block_given?

        if has_expr && has_block
          raise_error("attribute '#{name}' cannot be called with both an expression and a block", loc)
        elsif !has_expr && !has_block
          raise_error("attribute '#{name}' requires an expression or a block.", loc)
        end

        expr =
          if blk
            build_cascade(name, loc, &blk)
          else
            ensure_syntax(expr, loc)
          end

        node = Attribute.new(name, expr)
        node.loc = loc
        @attributes << node
      end

      def trait(name, lhs, operator, rhs)
        loc = current_location
        validate_name(name, :trait, loc)
        raise_error("expects a symbol for an operator, got #{operator.class}", loc) unless operator.is_a?(Symbol)

        expr = CallExpression.new(operator, [ensure_syntax(lhs, loc), ensure_syntax(rhs, loc)])

        unless TraitEngine::OperatorRegistry.supported?(operator)
          raise_error("operator `#{operator}` is not supported", loc)
        end

        node = Trait.new(name, expr)
        node.loc = loc
        @traits << node
      end

      def function(name, call_expr)
        loc = current_location
        validate_name(name, :function, loc)
        unless call_expr.is_a?(CallExpression)
          raise_error("must be defined with a `call(...)`, got #{call_expr.class}",
                      loc)
        end

        node = Function.new(name, call_expr)
        node.loc = loc
        @functions << node
      end

      def field(name)
        node = Field.new(name)
        node.loc = current_location
        node
      end

      def ref(name)
        node = Binding.new(name)
        node.loc = current_location
        node
      end

      def literal(value)
        node = Literal.new(value)
        node.loc = current_location
        node
      end

      def call(fn_name, *args)
        loc = current_location
        expr_args = args.map { |a| ensure_syntax(a, loc) }
        node = CallExpression.new(fn_name, expr_args)
        node.loc = loc
        node
      end

      private

      def validate_name(name, type, location)
        return if name.is_a?(Symbol)

        raise_error("The name for '#{type}' must be a Symbol, got #{name.class}", location)
      end

      def ensure_syntax(obj, location)
        case obj
        when Integer, String, Symbol, TrueClass, FalseClass then literal(obj)
        when Array then ListExpression.new(obj.map { |e| ensure_syntax(e, location) })
        when Syntax::Node then obj
        else
          raise_error("Invalid expression: #{obj.inspect}", location)
        end
      end

      def current_location
        TraitEngine.current_location
      end

      def raise_error(message, location)
        raise Errors::SyntaxError, "at #{location.file}:#{location.line}: #{message}"
      end

      def build_cascade(name, loc, &blk)
        cascade_builder = DslCascadeBuilder.new(self)
        cascade_builder.instance_eval(&blk)

        expr = CascadeExpression.new(cascade_builder.cases, cascade_builder.default)
        expr.loc = loc

        expr
      end

      def current_location
        # if proxy set @last_loc, use it; otherwise fallback as before
        return last_loc if last_loc

        fallback = caller_locations.find { |loc| loc.absolute_path }
        Syntax::Location.new(file: fallback.path, line: fallback.lineno, column: 0)
      end
    end
  end
end
