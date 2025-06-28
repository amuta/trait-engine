# frozen_string_literal: true

module TraitEngine
  class Function
    attr_reader :name, :method_name, :arg_descriptors, :body_proc

    def initialize(name:, method_name:, arg_descriptors:, &body)
      @name            = name.to_sym
      @method_name     = method_name.to_sym
      @arg_descriptors = arg_descriptors.freeze
      @body_proc       = body
    end

    # used by graph/explain
    def deps
      arg_descriptors
        .select { |d| %i[field attribute function].include?(d[:type]) }
        .map    { |d| d[:value] }
    end

    def call(processor, ctx)
      body_proc.call(processor, ctx)
    end
  end
end
