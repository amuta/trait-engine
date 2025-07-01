module TraitEngine
  class UnknownOperator < StandardError; end

  module OperatorRegistry
    Entry = Struct.new(:fn, :arity, :types)

    @ops = {
      :== => Entry.new(->(a, b) { a == b }, 2, %i[any any]),
      :> => Entry.new(->(a, b) { a >  b }, 2, %i[numeric numeric]),
      :< => Entry.new(->(a, b) { a <  b }, 2, %i[numeric numeric]),
      :>= => Entry.new(->(a, b) { a >= b }, 2, %i[numeric numeric]),
      :<= => Entry.new(->(a, b) { a <= b }, 2, %i[numeric numeric])
    }.freeze

    class << self
      def fetch(op_sym)
        entry = @ops[op_sym]
        raise UnknownOperator, "Operator #{op_sym.inspect} not supported" unless entry

        entry.fn
      end

      def signature(op_sym)
        entry = @ops[op_sym]
        raise UnknownOperator unless entry

        { arity: entry.arity, types: entry.types }
      end

      def supported?(op_sym)
        @ops.key?(op_sym)
      end
    end
  end
end
