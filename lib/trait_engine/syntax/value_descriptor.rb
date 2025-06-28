module TraitEngine
  module Syntax
    ValueDescriptor = Struct.new(:type, :value, keyword_init: true) do
      def to_h = { type: type, value: value }
    end
  end
end
