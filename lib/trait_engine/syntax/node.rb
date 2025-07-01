module TraitEngine
  module Syntax
    # A struct to hold standardized source location information.
    Location = Struct.new(:file, :line, :column, keyword_init: true)

    # Base module included by all AST nodes to provide a standard
    # interface for accessing source location information..
    module Node
      attr_accessor :loc
    end
  end
end
