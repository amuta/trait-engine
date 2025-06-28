# frozen_string_literal: true

require_relative "schema"
require_relative "decision_table"
require_relative "trait"
require_relative "attribute"
require_relative "function"
require_relative "registry"
require_relative "resolvers"

module TraitEngine
  # Turns an Syntax::Schema into an executable TraitEngine::Schema
  class SchemaCompiler
    class << self
      # public API
      def compile(ast)
        new(ast).build
      end
    end

    def initialize(ast)
      @ast = ast
      @traits     = {}
      @functions  = {}
      @attributes = {}
    end

    def build
      compile_traits
      compile_functions
      compile_attributes
      TraitEngine::Schema.new(
        traits: @traits,
        functions: @functions,
        attributes: @attributes
      )
    end

    private

    def compile_traits
      @ast.traits.each do |t|
        @traits[t.name] = TraitEngine::Trait.new(
          t.name,
          &predicate_lambda(t.predicate_descriptor)
        )
      end
    end

    # turns predicate descriptor hash into lambda
    def predicate_lambda(desc)
      lhs_resolver = Resolvers::Factory.build(**desc[:lhs])
      rhs_value  = desc[:rhs][:value]
      op         = desc[:op]

      lambda do |ctx|
        lhs = lhs_resolver.value(nil, ctx)
        compare(lhs, rhs_value, op)
      end
    end

    def compare(a, b, op)
      case op
      when :eq  then a == b
      when :neq then a != b
      when :gt  then a.to_f >  b.to_f
      when :gte then a.to_f >= b.to_f
      when :lt  then a.to_f <  b.to_f
      when :lte then a.to_f <= b.to_f
      else false
      end
    end

    # ------------------- functions -----------------------------
    def compile_functions
      @ast.functions.each do |fn|
        @functions[fn_node.name] = build_function_obj(fn_node)
      end
    end

    def build_function_obj(fn_node)
      arg_descs = fn_node.arg_descriptors.map(&:dup).freeze
      core_proc = TraitEngine::CoreFuncs::REGISTRY.fetch(fn_node.method_name)

      TraitEngine::Function.new(
        name: fn_node.name,
        method_name: fn_node.method_name,
        arg_descriptors: arg_descs
      ) do |processor, ctx|
        args = arg_descs.map do |d|
          case d[:type]
          when :literal   then d[:value]
          when :attribute then processor.resolve_attribute(d[:value], ctx)
          when :field     then ctx[d[:value]]
          when :function  then processor.resolve_function(d[:value], ctx)
          end
        end
        core_proc.call(*args)
      end
    end

    def compile_attributes
      @ast.attributes.each do |a_node|
        if a_node.simple?
          resolver = Resolvers::Factory.build(**a_node.cases.first.resolver_descriptor)
          @attributes[a_node.name] = Attribute.new(name: a_node.name, resolver_or_table: resolver)
        else
          rows = a_node.cases.map do |c|
            [
              c.trait_names,
              Resolvers::Factory.build(**c.resolver_descriptor)
            ]
          end
          table = DecisionTable.new(rows)
          @attributes[a_node.name] = Attribute.new(name: a_node.name, resolver_or_table: table)
        end
      end
    end
  end
end
