# lib/trait_engine/dsl/builder.rb
# frozen_string_literal: true

require "forwardable"
require "trait_engine/syntax/nodes"

module TraitEngine
  module DSL
    #
    # Schema-level DSL entry-point.
    # Produces a `TraitEngine::Syntax::Schema`.
    #
    class SchemaBuilder
      attr_reader :attributes, :traits, :functions

      # == Entry point ========================================================
      def self.build(&block)
        instance = new
        instance.instance_eval(&block)
        TraitEngine::Syntax::Schema.new(
          attributes: instance.attributes,
          traits: instance.traits,
          functions: instance.functions
        )
      end

      # ----------------------------------------------------------------------

      def initialize
        @attributes = []
        @traits     = []
        @functions  = []
      end

      # ── DSL primitives ────────────────────────────────────────────────────

      # attribute :name, field(:age)
      # attribute :name do … end
      def attribute(name, expr = nil, &blk)
        node =
          if blk
            builder = CascadeBuilder.new(self)
            builder.instance_eval(&blk)
            builder.to_expression
          else
            raise ArgumentError, "attribute #{name}: missing expression" unless expr

            ensure_expr(expr)
          end

        @attributes << Syntax::Attribute.new(name: name, expression: node)
      end

      # trait :is_underage, field(:age), :less_than, 18
      def trait(name, lhs, operator, rhs)
        lhs_node = ensure_expr(lhs)
        rhs_node = ensure_expr(rhs)
        call     = Syntax::CallExpression.new(
          fn_name: operator,
          arguments: [lhs_node, rhs_node]
        )
        @traits << Syntax::Trait.new(name: name, expression: call)
      end

      # function :foo, call(:bar, field(:baz))
      def function(name, call_expr)
        @functions << Syntax::Function.new(name: name, body: ensure_expr(call_expr))
      end

      # ── Expression helpers ────────────────────────────────────────────────

      def field(name)  = Syntax::Field.new(identifier: name)
      def ref(name)    = Syntax::BindingRef.new(name: name)
      def literal(v)   = Syntax::Literal.new(value: v)

      def call(fn, *args)
        Syntax::CallExpression.new(
          fn_name: fn,
          arguments: args.map { |a| ensure_expr(a) }
        )
      end

      # ----------------------------------------------------------------------

      private

      def ensure_expr(obj)
        case obj
        when Syntax::Node
          obj
        when Array
          Syntax::ListExpression.new(elements: obj.map { |e| ensure_expr(e) })
        else
          Syntax::Literal.new(value: obj)
        end
      end

      #
      # Nested helper for the cascade { … } block inside attribute definitions.
      #
      class CascadeBuilder
        extend Forwardable

        attr_reader :cases, :default

        def initialize(parent)
          @parent  = parent
          @cases   = []
          @default = nil
        end

        # expose expression helpers (field, ref, literal, call)
        def_delegators :@parent, :field, :ref, :literal, :call

        # on_trait  :foo, 'yes'
        def on_trait(name, expr)
          @cases << [ref(name), ensure_expr(expr)]
        end

        # on_traits :a, :b, 'yes'
        def on_traits(*names, result)
          @cases << [Syntax::ListExpression.new(elements: names.map { |n| ref(n) }), ensure_expr(result)]
        end

        # default 'maybe'
        def default(expr)
          @default = ensure_expr(expr)
        end

        def to_expression
          Syntax::CascadeExpression.new(cases: @cases, default: @default)
        end

        private

        def ensure_expr(obj)
          @parent.send(:ensure_expr, obj)
        end
      end
    end
  end
end
