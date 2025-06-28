# frozen_string_literal: true

module TraitEngine
  module Syntax
    module Nodes
      Trait = Struct.new(
        :name, # Symbol
        :predicate_descriptor, # Classify::PredicateDescriptor
        :loc, # Syntax::Location
        keyword_init: true
      ) do
        def to_h
          { type: :trait, name: name, loc: loc.to_h }
        end
      end
    end
  end
end
