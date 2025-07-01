module TraitEngine
  module Syntax
    # Represents the root of the Abstract Syntax Tree.
    # It holds all the top-level declarations parsed from the source.
    Schema = Struct.new(:attributes, :traits, :functions)
  end
end
