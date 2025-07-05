module Kumi
  class Linker
    attr_reader :schema, :dependency_graph

    def self.link!(schema)
      new(schema).link!
    end

    def initialize(schema)
      @schema = schema
      @names  = {}
      @dependency_graph = {}
      @leaf_map = Hash.new { |h, k| h[k] = Set.new }
    end

    def link!
      # Pass 1: Index all definitions
      index_definitions

      # Pass 2: Walk all nodes once and validate everything
      validate_all_nodes

      # Pass 3: Detect cycles using the dependency graph built in pass 2
      detect_cycles

      self
    end

    def leaf_fields(binding_name)
      @leaf_map[binding_name].dup.freeze
    end

    private

    def walk(node, visited = Set.new, &blk)
      return if visited.include?(node)

      visited << node
      blk.call(node)
      node.children.each { |child| walk(child, visited, &blk) }
    end

    def all_nodes
      @schema.attributes + @schema.traits
    end

    def index_definitions
      all_nodes.each do |node|
        err(node.loc, "duplicate definition of `#{node.name}`") if @names.key?(node.name)
        @names[node.name] = node
      end
    end

    def validate_all_nodes
      all_nodes.each do |decl|
        refs = []

        walk(decl) do |node|
          case node
          when Syntax::TerminalExpressions::Binding
            # Validate binding exists
            err(node.loc, "undefined reference to `#{node.name}`") unless @names.key?(node.name)
            refs << node.name
            # Track leaf fields for this binding
          when Syntax::Expressions::CallExpression
          # Validate operators have correct arity
          # validate_operator_arity(node)
          when Syntax::TerminalExpressions::Field
            @leaf_map[decl.name] << node.name      # collect leaves
          when Syntax::TerminalExpressions::Literal
            @leaf_map[decl.name] << node.value     # optional, keep literals

          end
        end

        # Build dependency graph for cycle detection
        @dependency_graph[decl.name] = refs
      end
    end

    def detect_cycles
      visited = Set.new
      stack   = []

      @dependency_graph.each_key do |name|
        dfs(name, visited, stack)
      end
    end

    def dfs(name, visited, stack)
      return if visited.include?(name)

      visited << name
      stack.push(name)

      Array(@dependency_graph[name]).each do |ref|
        if stack.include?(ref)
          cycle = (stack + [ref]).join(" → ")
          raise Errors::SemanticError, "cycle detected: #{cycle}"
        end
        dfs(ref, visited, stack)
      end

      stack.pop
    end

    def validate_operator_arity(call_node)
      MethodCallRegistry.confirm_support!(call_node.fn_name)
      op = call_node.fn_name
      sig = MethodCallRegistry.signature(op)
      expected = sig[:arity]
      given = call_node.args.size

      return if expected.negative? # means fn(*args), no arity check
      return unless given != expected

      err(call_node.loc,
          "operator `#{op}` expects #{expected} arguments, got #{given}")
    rescue Kumi::MethodCallRegistry::UnknownMethodName
      err(call_node.loc, "unsupported operator `#{call_node.fn_name}`")
    end

    def err(loc, message)
      raise Errors::SemanticError, "at #{loc.file}:#{loc.line}: #{message}"
    end
  end
end
