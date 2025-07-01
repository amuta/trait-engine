require_relative "node"

module TraitEngine
  module Syntax
    module Declarations
      Attribute = Struct.new(:name, :expression) { include Node }
      Trait     = Struct.new(:name, :expression) { include Node }
      Function  = Struct.new(:name, :expression) { include Node }
    end
  end
end
