module Kumi
  class Compiler
    def self.compile(schema)
      new(schema).compile
    end

    def initialize(schema)
      @schema = schema
      @bindings = {}
    end

    def compile
      # Compile all declarations
      @schema.attributes.each { |attr| @bindings[attr.name] = [:attr, compile_expr(attr.expression)] }
      @schema.traits.each { |trait| @bindings[trait.name] = [:trait, compile_expr(trait.expression)] }

      ExecutableSchema.new(@bindings)
    end

    private

    def compile_expr(expr)
      case expr
      when Syntax::TerminalExpressions::Literal
        value = expr.value
        ->(ctx) { value }

      when Syntax::TerminalExpressions::Field
        field = compile_field(expr)

      when Syntax::TerminalExpressions::Binding
        name = expr.name
        lambda { |ctx|
          @bindings[name][1].call(ctx)
        }

      when Syntax::Expressions::ListExpression
        elements = expr.elements.map { |e| compile_expr(e) }
        ->(ctx) { elements.map { |fn| fn.call(ctx) } }

      when Syntax::Expressions::CallExpression
        fn_name = expr.fn_name
        args = expr.args.map { |arg| compile_expr(arg) }
        lambda do |ctx|
          compile_call(fn_name, args, ctx, source_loc: expr.loc)
        end

      when Syntax::Expressions::CascadeExpression
        cases = expr.cases.map { |c| [compile_expr(c.condition), compile_expr(c.result)] }
        lambda do |ctx|
          cases.each { |cond, result| return result.call(ctx) if cond.call(ctx) }
          nil
        end

      else
        raise "Unknown expression type: #{expr.class}"
      end
    end

    def compile_field(expr)
      field_name = expr.name
      source_loc = expr.loc

      lambda do |ctx|
        return ctx[field_name] if ctx.key?(field_name)

        # Rich error with compilation context
        error = Errors::RuntimeError.new(
          "Key '#{field_name}' not found in context. Available keys: #{ctx.keys.join(", ")}"
        )

        raise error
      end
    end

    def compile_call(fn_name, args, ctx, source_loc: nil)
      fn = Kumi::MethodCallRegistry.fetch(fn_name)
      raise Errors::RuntimeError, "Function fn(:#{fn_name}) not found" unless fn

      # Call the function with the provided context and arguments
      arg_values = args.map { |arg| arg.call(ctx) }

      begin
        fn.call(*arg_values)
      rescue StandardError => e
        # Wrap the error with context information
        raise Errors::RuntimeError.new("Error calling fn(:#{fn_name}): #{e.message}")
      end
    end
  end

  class ExecutableSchema
    def initialize(bindings)
      @bindings = bindings
    end

    def evaluate(data)
      {
        attributes: evaluate_attributes(data),
        traits: evaluate_traits(data)
      }
    end

    def evaluate_traits(data)
      validate_data(data)
      trait_bindings.transform_values { |kind, fn| fn.call(data) }
    end

    def evaluate_attributes(data)
      validate_data(data)
      attribute_bindings.transform_values { |kind, fn| fn.call(data) }
    end

    def evaluate_binding(name, data)
      _, fn = @bindings[name]
      raise Errors::RuntimeError, "No binding found: #{name}" unless fn

      fn.call(data)
    end

    private

    def trait_bindings
      @bindings.select { |_, v| v[0] == :trait }
    end

    def attribute_bindings
      @bindings.select { |_, v| v[0] == :attr }
    end

    def validate_data(data)
      return if data.is_a? Hash
      return if data.respond_to?(:key?) && data.respond_to?(:[])

      raise Errors::RuntimeError, "Data context should be a Hash-like object and respond to `:key?` and `:[]` methods."
    end
  end
end
