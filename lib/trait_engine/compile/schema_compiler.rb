# lib/trait_engine/compile/schema_compiler.rb
# frozen_string_literal: true

require_relative "../runtime/schema"
require_relative "../runtime/trait"
require_relative "../runtime/function"
require_relative "../runtime/attribute"
require_relative "../runtime/decision_table"
require_relative "../runtime/resolvers/factory"
require_relative "../syntax/value_descriptor"

module TraitEngine
  module Compile
    # Transforms a Syntax::SchemaNode into an executable Runtime::Schema
    class SchemaCompiler
      def self.compile(ast)
        new(ast).compile
      end

      def initialize(ast)
        @ast        = ast
        @traits     = {}
        @functions  = {}
        @attributes = {}
      end

      # Orchestrates the full compilation process
      def compile
        compile_traits
        compile_functions
        compile_attributes

        Runtime::Schema.new(
          traits: @traits.freeze,
          functions: @functions.freeze,
          attributes: @attributes.freeze
        )
      end

      private

      # ─── 1) Traits ────────────────────────────────────────────
      def compile_traits
        @ast.traits.each do |node|
          @traits[node.name] = Runtime::Trait.new(
            node.name,
            &build_predicate_lambda(node.predicate_descriptor)
          )
        end
      end

      def build_predicate_lambda(desc)
        lhs_resolver = Runtime::Resolvers::Factory.build(desc[:lhs])
        rhs_value    = desc[:rhs][:value]
        op           = desc[:op]

        lambda do |ctx|
          lhs = lhs_resolver.value(nil, ctx)
          compare(lhs, rhs_value, op)
        end
      end

      def compare(a, b, op)
        # numeric comparison for >,< etc; fallback to string eq/neq
        case op
        when :eq  then a == b
        when :neq then a != b
        when :gt  then a.to_f >  b.to_f
        when :gte then a.to_f >= b.to_f
        when :lt  then a.to_f <  b.to_f
        when :lte then a.to_f <= b.to_f
        else
          false
        end
      end

      # ─── 2) Functions ─────────────────────────────────────────
      def compile_functions
        @ast.functions.each do |node|
          @functions[node.name] = build_function_wrapper(node)
        end
      end

      def build_function_wrapper(fn_node)
        # instantiate resolver objects for each argument descriptor
        arg_resolvers = fn_node.arg_descriptors.map do |desc|
          Runtime::Resolvers::Factory.build(desc)
        end

        # fetch the shared or builtin function implementation
        core_proc = TraitEngine::SharedFunctions::REGISTRY.fetch(fn_node.method_name)

        Runtime::Function.new(
          name: fn_node.name,
          method_name: fn_node.method_name,
          arg_descriptors: fn_node.arg_descriptors.freeze
        ) do |processor, ctx|
          # delegate actual resolution to each resolver
          values = arg_resolvers.map { |r| r.value(processor, ctx) }
          core_proc.call(*values)
        end
      end

      # ─── 3) Attributes ────────────────────────────────────────
      def compile_attributes
        @ast.attributes.each do |node|
          @attributes[node.name] =
            if node.simple?
              resolver = Runtime::Resolvers::Factory.build(node.cases.first.resolver_descriptor)
              Runtime::Attribute.new(name: node.name, value_from: resolver)
            else
              rows = node.cases.map do |c|
                [c.trait_names,
                 Runtime::Resolvers::Factory.build(c.resolver_descriptor)]
              end
              table = Runtime::DecisionTable.new(rows)
              Runtime::Attribute.new(name: node.name, value_from: table)
            end
        end
      end
    end
  end
end
