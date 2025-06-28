# frozen_string_literal: true

module TraitEngine
  module AST
    SchemaNode = Struct.new(
      :traits,     # Array<TraitNode>
      :functions,  # Array<FunctionNode>
      :attributes, # Array<AttributeNode>
      :loc         # AST::Location
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
