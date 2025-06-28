require_relative "token"
require_relative "../ast/location"

module TraitEngine
  module Lex
    class ScalarLexer
      RULES = {
        /^(>=|<=|!=|==|>|<)/ => :op,
        /^\d+/                      => :int,

        # quoted strings (“…” or '…')
        /^"(?:[^"\\]|\\.)*"/        => :string,
        /^'(?:[^'\\]|\\.)*'/        => :string,

        /^field(?=:)/     => :kw_field,
        /^literal(?=:)/   => :kw_literal,
        /^attribute(?=:)/ => :kw_attribute,
        /^function(?=:)/  => :kw_function,
        /^:/        => :colon,
        /^,/          => :comma,
        /^:?\w+/        => :ident,
        /^:?\s+/        => :ws
      }.freeze

      def initialize(source, file:, line: 1, col: 1)
        @src, @file, @line, @col = source.dup, file, line, col
      end

      def tokens
        each_token.to_a
      end

      def each_token
        return enum_for(:each_token) unless block_given?
        until @src.empty?
          token = next_token
          next if token.kind == :ws
          yield token
        end
      end

      private

      def next_token
        RULES.each do |re, kind|
          if (m = @src.match(re))
            txt = m[0]
            tok = Lex::Token.new(kind:, text: txt, loc: loc_now)
            advance(txt)
            return tok
          end
        end

        message = "could not be tokenized: #{@src[0, 5].inspect}..."
        raise TraitEngine::ValidationError.new(
          code: "LEX001",
          message: message,
          loc: loc_now
        )
      end

      def loc_now
        AST::Location.new(file: @file, line: @line, column: @col)
      end

      def advance(text)
        lines = text.count("\n")
        if lines.zero?
          @col += text.length
        else
          @line += lines
          @col   = text.length - text.rindex("\n")
        end
        @src.slice!(0, text.length)
      end
    end
  end
end
