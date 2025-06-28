# frozen_string_literal: true

require "yaml"
require "psych"

require_relative "../lex/scalar_lexer"
require_relative "../classify/resolver_classifier"
require_relative "../classify/predicate_parser"
require_relative "../ast/location"
require_relative "../ast/trait_node"
require_relative "../ast/function_node"
require_relative "../ast/conditional_case_node"
require_relative "../ast/attribute_node"
require_relative "../ast/schema_node"

module TraitEngine
  module Loaders
    class YamlLoader
      def self.load(path)
        new(path).to_ast
      end

      def initialize(path)
        @file = path
        @doc  = Psych.parse_file(path) # full node tree
      end

      def to_ast
        root_map = mapping_to_hash(@doc.root)

        AST::SchemaNode.new(
          traits: build_traits(root_map["traits"]),
          functions: build_functions(root_map["functions"]),
          attributes: build_attributes(root_map["attributes"]),
          loc: loc(@doc.root)
        )
      end

      # -------------- traits ----------------------------------

      def build_traits(node)
        return [] unless node

        kv_pairs(node).map do |trait_name_node, mapping_node|
          # mapping_node is a Mapping; pick its first child pair
          tokens = Lex::ScalarLexer.new(mapping_node.value, file: @file).tokens
          predicate_desc = Classify::PredicateParser.from_tokens(tokens)

          AST::TraitNode.new(
            name: trait_name_node.value.to_sym,
            predicate_descriptor: predicate_desc,
            loc: loc(trait_name_node)
          )
        end
      end

      # -------------- functions -------------------------------

      def build_functions(node)
        return [] unless node

        kv_pairs(node).map do |fn_name_node, fn_map_node|
          fn_hash = mapping_to_hash(fn_map_node)
          args = Array(fn_hash["arguments"].children).map do |arg_node|
            parse_resolver(arg_node.value, arg_node)
          end

          AST::FunctionNode.new(
            name: fn_name_node.value.to_sym,
            method_name: fn_hash["method"].value.to_sym,
            arg_descriptors: args,
            loc: loc(fn_name_node)
          )
        end
      end

      def build_attributes(node)
        return [] unless node

        kv_pairs(node).map do |attr_name_node, value_node|
          cases = if value_node.is_a?(Psych::Nodes::Sequence) # decision table
                    value_node.children.map do |decision_node|
                      trait_syms = decision_node.children[1].children.map { |trait_node| trait_node.value.to_sym }
                      resolver_node = decision_node.children[3] # resolver node is always the 4th
                      AST::ConditionalCaseNode.new(
                        trait_names: trait_syms,
                        resolver_descriptor: parse_resolver(resolver_node.value, resolver_node),
                        loc: loc(decision_node)
                      )
                    end
                  else
                    [AST::ConditionalCaseNode.new(
                      trait_names: [],
                      resolver_descriptor: parse_resolver(value_node.value, value_node),
                      loc: loc(value_node)
                    )]
                  end

          AST::AttributeNode.new(
            name: attr_name_node.value.to_sym,
            cases: cases,
            loc: loc(attr_name_node)
          )
        end
      end

      # -------------- helpers ---------------------------------

      def parse_resolver(raw, node)
        tokens = Lex::ScalarLexer.new(raw, file: @file, line: node.start_line + 1, col: node.start_column).tokens
        Classify::ResolverClassifier.from_tokens(tokens)
      rescue TraitEngine::ValidationError => e
        e.loc ||= loc(node)

        raise
      end

      # yield [key_node, val_node] for every mapping entry
      def kv_pairs(mapping_node)
        mapping_node.children.each_slice(2)
      end

      # quick and dirty “mapping node ⇒ hash {string => node}”
      def mapping_to_hash(mapping_node)
        kv_pairs(mapping_node).to_h { |k, v| [k.value, v] }
      end

      def loc(node)
        AST::Location.new(
          file: @file,
          line: node.start_line + 1,
          column: node.start_column
        )
      end
    end
  end
end
