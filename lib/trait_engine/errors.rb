module TraitEngine
  module Errors
    class Error < StandardError; end

    class LocatedError < Error
      attr_reader :location

      def initialize(message, location = nil)
        super(message)
        @location = location
      end

      def to_s
        if @location
          "#{super} at #{@location.file}:#{@location.line}:#{@location.column}"
        else
          super
        end
      end
    end

    class SemanticError < LocatedError; end

    class SyntaxError < LocatedError; end

    class RuntimeError < Error
      attr_accessor :metadata

      def detailed_message
        msg = message
        if metadata && metadata[:defined_at]
          msg += "\n  Defined at: #{metadata[:defined_at].file}:#{metadata[:defined_at].line}"
        end
        msg
      end
    end
  end
end
