# frozen_string_literal: true

module TraitEngine
  module AST
    AttributeNode = Struct.new(
      :name,   # Symbol
      :cases,  # Array<ConditionalCaseNode>
      :loc,    # AST::Location
      keyword_init: true
    ) do
      def simple?
        cases.size == 1 && cases.first.trait_names.empty?
      end

      def to_h
        {
          name: name,
          cases: cases.map(&:to_h),
          loc: loc.to_h
        }
      end
    end
  end
end
