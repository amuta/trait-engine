# frozen_string_literal: true

require_relative "../registry"

module TraitEngine
  module Functions
    module Core
      extend self

      Registry.register(:literal)      { |v| v } # returns literal value
      Registry.register(:upcase)       { |v| v.to_s.upcase }
      Registry.register(:downcase)     { |v| v.to_s.downcase }
      Registry.register(:concatenate)  { |*args| args.join }
      Registry.register(:truncate)     { |v, len| v.to_s[0, len.to_i] }
    end
  end
end
