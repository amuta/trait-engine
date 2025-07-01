require "trait_engine/parser/dsl"

class InvalidSchema
  extend TraitEngine::Parser::Dsl

  schema do
    # this line should trigger our “missing expr” error
    attribute :name
  end
end
