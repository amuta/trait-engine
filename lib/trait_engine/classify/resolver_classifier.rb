# frozen_string_literal: true

require_relative "../errors"
require_relative "../descriptors/value_descriptor"

module TraitEngine
  module Classify
    class ResolverClassifier
      using(Module.new do
        refine Array do
          def kinds = map(&:kind)
          def text_at(i) = self[i]&.text
        end
      end)

      # tokens -> Descriptors::ValueDescriptor
      def self.from_tokens(tokens)
        kinds = tokens.kinds

        desc =
          case kinds
          when %i[kw_field colon ident]
            [:field, tokens.text_at(2).to_sym]

          when %i[kw_literal colon ident]
            [:literal, tokens.text_at(2)]

          when %i[kw_attribute colon ident]
            [:attribute, tokens.text_at(2).to_sym]

          when %i[kw_function colon ident]
            # no args at scalar level; compiler will inject arg_descriptors later
            [:function, [tokens.text_at(2).to_sym, []]]

          else
            loc = tokens.first.loc
            raise TraitEngine::ValidationError.new(
              code: "ORG001",
              message: "unknown resolver pattern #{kinds.inspect}",
              loc: loc,
              path: []
            )
          end

        TraitEngine::Descriptors::ValueDescriptor.new(type: desc[0], value: desc[1]).freeze
      end
    end
  end
end
