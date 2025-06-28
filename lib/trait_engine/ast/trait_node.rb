# frozen_string_literal: true

module TraitEngine
  module AST
    TraitNode = Struct.new(
      :name, # Symbol
      :predicate_descriptor, # Classify::PredicateDescriptor
      :loc, # AST::Location
      keyword_init: true
    ) do
      def to_h
        { type: :trait, name: name, loc: loc.to_h }
      end
    end
  end
end
