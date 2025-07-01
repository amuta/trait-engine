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

    class SyntaxError < LocatedError; end
  end
end
