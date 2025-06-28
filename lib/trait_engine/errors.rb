# frozen_string_literal: true

module TraitEngine
  # Root for every library-specific exception
  class Error < StandardError; end

  # ---------- validation / build-time --------------------------------
  class ValidationError < Error
    attr_reader :code, :path
    attr_accessor :loc

    # @param code [String] short error code (eg. "FN001")
    # @param path [Array<Symbol,String>] node path within schema
    def initialize(code:, message:, loc: nil, path: [])
      @code = code
      super("[#{code}] #{message} (at #{loc})")
    end
  end

  # ---------- runtime ------------------------------------------------
  class UnknownFunctionError   < Error; end
  class CycleError             < Error; end
  class RegistryFrozenError    < Error; end
end
