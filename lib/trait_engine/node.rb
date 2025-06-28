# frozen_string_literal: true

module TraitEngine
  # Generic graph node (trait, function, or attribute)
  Node = Struct.new(
    :id,      # Symbol
    :type,    # :trait | :function | :attribute
    :deps,    # Array<Symbol>
    :meta,    # Hash (additional info)
    keyword_init: true
  ) do
    def to_h
      { id: id, type: type, deps: deps, meta: meta }
    end
  end
end
