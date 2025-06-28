# frozen_string_literal: true

require_relative "errors"
require_relative "function" # runtime wrapper

module TraitEngine
  # Executes a compiled Schema against a concrete context Hash.
  #
  #  • memo-izes every resolved attribute / function
  #  • detects cycles and raises CycleError with a readable path
  #  • records a minimal trace so `#explain` can replay why a value was chosen
  #
  class Processor
    attr_reader :schema

    def initialize(schema)
      @schema = schema
      @memo   = {}          # { cache_key => value }
      @trace  = {}          # { cache_key => { resolver:, traits: } }
      @stack  = []          # call stack for cycle detection
    end

    # ------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------

    # Resolve a derived attribute
    def resolve_attribute(name, ctx)
      key = :"attr_#{name}"
      return @memo[key] if @memo.key?(key)

      detect_cycle!(key)
      @stack << key

      attr_obj = schema.fetch_attribute(name) or
        raise UnknownAttributeError, name

      traits_truth = matched_traits(ctx)
      resolver_value = attr_obj.value(self, ctx, traits_truth)

      @memo[key]  = resolver_value
      @trace[key] = { resolver: attr_obj.simple? ? attr_obj.deps : attr_obj.inspect,
                      traits: traits_truth.to_a }

      resolver_value
    ensure
      @stack.pop
    end

    # Resolve a function result
    def resolve_function(name, ctx)
      key = :"fn_#{name}"
      return @memo[key] if @memo.key?(key)

      detect_cycle!(key)
      @stack << key

      fn = schema.fetch_function(name) or
        raise UnknownFunctionError, name

      value = fn.call(self, ctx)

      @memo[key]  = value
      @trace[key] = { method: fn.method_name, args: fn.arg_descriptors }

      value
    ensure
      @stack.pop
    end

    # Human-readable JSON-compatible explanation
    def explain(attr_name, ctx)
      resolve_attribute(attr_name, ctx) unless @memo.key?(:"attr_#{attr_name}")
      key = :"attr_#{attr_name}"
      build_explain_tree(key)
    end

    # ------------------------------------------------------------
    private

    def matched_traits(ctx)
      @matched_cache ||= {}
      @matched_cache[ctx.object_id] ||= begin
        set = schema.traits.values
                    .select { |t| t.call(ctx) }
                    .map(&:name)
                    .to_set
        set.freeze
      end
    end

    def detect_cycle!(key)
      return unless @stack.include?(key)

      cycle = (@stack + [key]).map { |k| k.to_s }.join(" -> ")
      raise CycleError, "dependency cycle detected: #{cycle}"
    end

    # Recursively reconstruct why an attribute/function got its value
    def build_explain_tree(cache_key)
      node = @trace[cache_key].dup
      deps =
        case cache_key
        when /\Aattr_(.+)\z/ then schema.fetch_attribute(Regexp.last_match(1).to_sym).deps
        when /\Afn_(.+)\z/   then schema.fetch_function(Regexp.last_match(1).to_sym).deps
        else []
        end

      node[:deps] = deps.map do |d|
        ck = d.is_a?(Symbol) ? :"attr_#{d}" : :"fn_#{d}"
        build_explain_tree(ck) if @trace.key?(ck)
      end.compact
      node
    end

    # --- custom errors ----------------------------------------
    class UnknownAttributeError < TraitEngine::Error; end
  end
end
