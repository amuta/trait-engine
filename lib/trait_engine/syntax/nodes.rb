# frozen_string_literal: true

module TraitEngine
  module Syntax
    # Holds source‐location metadata for AST nodes
    Location = Struct.new(:file, :line, :column, keyword_init: true)

    # Base class for every AST node, providing a `loc` accessor
    class Node
      # @return [Location, nil]
      attr_accessor :loc

      # @param loc [Location, nil]
      def initialize(loc: nil)
        @loc = loc
      end
    end

    class Schema < Node
      attr_reader :attributes, :traits, :functions

      def initialize(attributes:, traits:, functions:, loc: nil)
        super(loc: loc)
        @attributes = attributes
        @traits     = traits
        @functions  = functions
      end
    end

    class Attribute < Node
      attr_reader :name, :expression

      def initialize(name:, expression:, loc: nil)
        super(loc: loc)
        @name = name
        @expression = expression
      end
    end

    class Trait < Node
      attr_reader :name, :expression

      def initialize(name:, expression:, loc: nil)
        super(loc: loc)
        @name       = name
        @expression = expression
      end
    end

    class Function < Node
      attr_reader :name, :body

      def initialize(name:, body:, loc: nil)
        super(loc: loc)
        @name = name
        @body = body
      end
    end

    class Literal < Node
      attr_reader :value

      def initialize(value:, loc: nil)
        super(loc: loc)
        @value = value
      end
    end

    class Field < Node
      attr_reader :identifier

      def initialize(identifier:, loc: nil)
        super(loc: loc)
        @identifier = identifier
      end
    end

    class BindingRef < Node
      attr_reader :name

      def initialize(name:, loc: nil)
        super(loc: loc)
        @name = name
      end
    end

    class Builder < Node
      attr_reader :steps

      def initialize(steps:, loc: nil)
        super(loc: loc)
        @steps = steps
      end
    end

    class CascadeBuilder < Builder
      # inherits steps and loc
    end

    class CallExpression < Node
      attr_reader :fn_name, :arguments

      def initialize(fn_name:, arguments:, loc: nil)
        super(loc: loc)
        @fn_name = fn_name
        @arguments = arguments
      end
    end

    class CascadeExpression < Node
      attr_reader :cases, :default

      def initialize(cases:, default:, loc: nil)
        super(loc: loc)
        @cases = cases
        @default = default
      end
    end

    class ListExpression < Node
      attr_reader :elements

      def initialize(elements:, loc: nil)
        super(loc: loc)
        @elements = elements
      end
    end
  end
end
