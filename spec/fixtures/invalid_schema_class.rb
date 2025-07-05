require "kumi/parser/dsl"

class InvalidSchema
  extend Kumi::Parser::Dsl

  schema do
    # this line should trigger our “missing expr” error
    attribute :name
  end
end
