# frozen_string_literal: true

module TraitEngine
  module Syntax
    module Nodes
      Attribute = Struct.new(
        :name,   # Symbol
        :cases,  # Array<ConditionalCase>
        :loc,    # Syntax::Location
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
end
