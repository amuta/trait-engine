# frozen_string_literal: true

module TraitEngine
  module Syntax
    module Nodes
      Function = Struct.new(
        :name,            # Symbol
        :method_name,     # Symbol
        :arg_descriptors, # Array<Hash>
        :loc,             # Syntax::Location
        keyword_init: true
      ) do
        def to_h
          {
            type: :function,
            name: name,
            method: method_name,
            args: arg_descriptors,
            loc: loc.to_h
          }
        end
      end
    end
  end
end
