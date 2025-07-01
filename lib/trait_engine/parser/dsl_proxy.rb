# lib/trait_engine/parser/dsl_proxy.rb
require "forwardable"

module TraitEngine
  module Parser
    class DslProxy
      DSL_METHODS = %i[
        attribute attribute_cascade trait function
        field ref literal call
      ].freeze

      def initialize(context)
        @context = context
      end

      DSL_METHODS.each do |meth|
        define_method(meth) do |*args, &blk|
          # grab exactly where the user invoked `attribute`, `call`, etc.
          c = caller_locations(1, 1).first
          @context.last_loc = Syntax::Location.new(
            file: c.path,
            line: c.lineno,
            column: 0
          )
          @context.public_send(meth, *args, &blk)
        end
      end
    end
  end
end
