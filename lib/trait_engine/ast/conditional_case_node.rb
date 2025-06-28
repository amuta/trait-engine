# frozen_string_literal: true

module TraitEngine
  module AST
    ConditionalCaseNode = Struct.new(
      :trait_names, # Array<Symbol>
      :resolver_descriptor, # Hash
      :loc, # AST::Location
      keyword_init: true
    ) do
      def to_h
        { traits: trait_names, resolver: resolver_descriptor, loc: loc.to_h }
      end
    end
  end
end
