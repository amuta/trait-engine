# frozen_string_literal: true

require_relative "errors"

module TraitEngine
  # Holds a list of `[trait_names, resolver]` rows (first match wins).
  #
  # trait_names : Array<Symbol>   (may be empty for default row)
  # resolver      : { type:, value: }   (exact structure will evolve)
  #
  class DecisionTable
    Row = Struct.new(:trait_names, :resolver, keyword_init: true)

    attr_reader :rows

    def initialize(rows)
      @rows = rows.map do |pair|
        Row.new(trait_names: Array(pair[0]).map(&:to_sym).to_set,
                resolver: pair[1])
      end
    end

    # Given a Set of satisfied trait symbols, return the chosen resolver
    def pick(matched_trait_set)
      @rows.each do |row|
        return row.resolver if (row.trait_names - matched_trait_set).empty?
      end
      raise TraitEngine::Error, "no decision-table match"
    end

    # Convenience for validation / graph deps
    def referenced_traits
      @rows.flat_map(&:trait_names).uniq
    end
  end
end
