require_relative "node"

module TraitEngine
  module AST
    # References a raw field from the input context
    class FieldRef < Node
      attr_reader :field_name

      def initialize(field_name:, loc: {})
        super(loc: loc)
        @field_name = field_name
      end
    end
  end
end
