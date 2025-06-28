# frozen_string_literal: true

require_relative "trait_engine/version"
require_relative "trait_engine/errors"
require_relative "trait_engine/registry"
require_relative "trait_engine/node"
require_relative "trait_engine/functions/core" # populate registry

# lex / classify / AST (empty for now)
require_relative "trait_engine/lex/token"
require_relative "trait_engine/lex/scalar_lexer"
require_relative "trait_engine/classify/resolver_classifier"
require_relative "trait_engine/classify/predicate_parser"
require_relative "trait_engine/ast/location"

require_relative "trait_engine/ast/trait_node"

require_relative "trait_engine/loaders/yaml_loader"

require_relative "trait_engine/processor"
require_relative "trait_engine/schema_compiler"

module TraitEngine
  # future high-level helpers live here
end
