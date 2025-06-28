# frozen_string_literal: true

require "trait_engine/errors"

module TraitEngine
  module Parse
    module Classifier
      class PredicateParser
        OP_TEXT_TO_SYM = {
          "==" => :eq,
          "!=" => :neq,
          ">" => :gt,
          ">=" => :gte,
          "<" => :lt,
          "<=" => :lte
        }.freeze

        # tokens -> predicate descriptor Hash
        #
        # returns:
        # {
        #   lhs:  { type: :attribute|:field, value: :tier },
        #   op:   :gt,
        #   rhs:  { type: :literal, value: 10 }
        # }.freeze
        #
        def self.from_tokens(tokens)
          kinds = tokens.map(&:kind)

          # basic length check
          unless kinds.size == 5 && kinds[3] == :op
            return raise_validation_error(tokens.first, "invalid predicate syntax")
          end

          op_sym = OP_TEXT_TO_SYM[tokens[3].text]
          raise_validation_error(tokens[3], "unrecognised operator #{tokens[3].text}") unless op_sym

          lhs_type =
            case kinds[0]
            when :kw_attribute then :attribute
            when :kw_field     then :field
            else
              return raise_validation_error(tokens[0], "lhs must be attribute: or field:")
            end

          lhs_name = tokens[2].text.to_sym
          rhs_token = tokens[4]
          rhs_value =
            case rhs_token.kind
            when :int then rhs_token.text.to_i
            when :string then rhs_token.text[1..-2] # remove quotes
            else rhs_token.text # ident
            end

          {
            lhs: TraitEngine::Syntax::ValueDdescescriptor.new(
              type: lhs_type,
              value: lhs_name
            ),
            op: op_sym,
            rhs: TraitEngine::Syntax::ValueDescriptor.new(
              type: :literal,
              value: rhs_value
            )
          }.freeze
        end

        def self.raise_validation_error(token, message)
          raise TraitEngine::ValidationError.new(
            code: "TRT001",
            message: message,
            loc: token.loc
          )
        end
        private_class_method :raise_validation_error
      end
    end
  end
end
