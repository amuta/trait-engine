# parse layer
require_relative "trait_engine/parse/lexer/token"
require_relative "trait_engine/parse/lexer/scalar_lexer"
require_relative "trait_engine/parse/classifier/resolver_classifier"
require_relative "trait_engine/parse/classifier/predicate_parser"

# syntax
require_relative "trait_engine/syntax/location"
require_relative "trait_engine/syntax/value_descriptor"
# load all node files via Dir
Dir[File.join(__dir__, "trait_engine/syntax/nodes/*.rb")].sort.each { |f| require_relative f }

module TraitEngine
  # future high-level helpers live here
end
