# frozen_string_literal: true

module TraitEngine
  module Syntax
    module Nodes
      Schema = Struct.new(
        :traits,     # Array<Trait>
        :functions,  # Array<Function>
        :attributes, # Array<Attribute>
        :loc         # Syntax::Location
      ) do
        def to_h
          {
            traits: traits.map(&:to_h),
            functions: functions.map(&:to_h),
            attributes: attributes.map(&:to_h),
            loc: loc.to_h
          }
        end
      end
    end
  end
end
