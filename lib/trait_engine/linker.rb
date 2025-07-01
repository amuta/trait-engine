require "trait_engine/errors"
require "trait_engine/syntax/schema"
require "trait_engine/syntax/declarations"
require "trait_engine/syntax/expressions"
require "trait_engine/syntax/terminal_expressions"
require "trait_engine/operator_registry"

module TraitEngine
  class Linker
    def self.link!(schema)
      new(schema).link!
    end

    def initialize(schema)
      @schema = schema
      @names  = {}
    end

    def link!
      index_definitions
      validate_bindings
      validate_cycles
      validate_operators
      validate_cascades
      @schema
    end

    private

    # ── Generic walker ─────────────────────────────────────────────────────────
    def walk(node, visited = Set.new, &blk)
      return if visited.include?(node)

      visited << node
      blk.call(node)
      node.children.each { |child| walk(child, visited, &blk) }
    end

    def all_nodes
      @schema.attributes + @schema.traits + @schema.functions
    end

    # ── 1) Duplicate‐name check ──────────────────────────────────────────────
    def index_definitions
      all_nodes.each do |node|
        err(node.loc, "duplicate definition of `#{node.name}`") if @names.key?(node.name)
        @names[node.name] = node
      end
    end

    # ── 2) Undefined‐binding check ───────────────────────────────────────────
    def validate_bindings
      all_nodes.each do |decl|
        walk(decl) do |n|
          next unless n.is_a?(Syntax::TerminalExpressions::Binding)

          err(n.loc, "undefined reference to `#{n.name}`") unless @names.key?(n.name)
        end
      end
    end

    # ── 3) Definition‐cycle detection ────────────────────────────────────────
    def validate_cycles
      graph = @names.transform_values do |node|
        refs = []
        walk(node) { |n| refs << n.name if n.is_a?(Syntax::TerminalExpressions::Binding) }
        refs
      end
      detect_cycles(graph)
    end

    def detect_cycles(graph)
      visited = Set.new
      stack   = []

      graph.each_key do |name|
        dfs(name, graph, visited, stack)
      end
    end

    def dfs(name, graph, visited, stack)
      return if visited.include?(name)

      visited << name
      stack.push(name)

      Array(graph[name]).each do |ref|
        if stack.include?(ref)
          cycle = (stack + [ref]).join(" → ")
          raise Errors::SemanticError, "cycle detected: #{cycle}"
        end
        dfs(ref, graph, visited, stack)
      end

      stack.pop
    end

    # ── 4) Cascade‐case sanity ────────────────────────────────────────────────
    def validate_cascades
      @schema.attributes.each do |attr|
        expr = attr.expression
        next unless expr.is_a?(Syntax::Expressions::CascadeExpression)

        seen = Set.new
        expr.cases.each do |cond, _|
          unless @schema.traits.any? { |t| t.name == cond.name }
            err(cond.loc, "cascade on unknown trait `#{cond.name}`")
          end
          err(cond.loc, "duplicate cascade case for `#{cond.name}`") if seen.include?(cond.name)
          seen << cond.name
        end
      end
    end

    def validate_operators
      @schema.traits.each do |trait|
        op       = trait.expression.fn_name
        sig      = TraitEngine::OperatorRegistry.signature(op)
        expected = sig[:arity]
        given    = trait.expression.args.size

        if given != expected
          err(trait.loc,
              "operator `#{op}` expects #{expected} arguments, got #{given}")
        end
      rescue TraitEngine::UnknownOperator
        err(trait.loc, "unsupported operator `#{op}`")
      end
    end

    # ── Error helper ─────────────────────────────────────────────────────────
    def err(loc, message)
      raise Errors::SemanticError, "at #{loc.file}:#{loc.line}: #{message}"
    end
  end
end
