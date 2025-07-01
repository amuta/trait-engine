

Declarative Dependency Graph

The System as a Declarative Dependency Graph
Nodes: The traits, functions, and attributes are the nodes in a computational graph.

Edges: The dependencies (from_column, attribute(...), on_trait, use_function) are the directed edges. They define how the value of one node is derived from others.

Resolution: Your Processor is not just a simple evaluator; it is a graph resolver. When a value for a node is requested, the engine traverses the graph, lazily resolving and memoizing the values of its dependencies until it can compute the final result.

