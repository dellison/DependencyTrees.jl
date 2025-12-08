# Graph Parsing

The `GraphParsing` submodule provides implementations of graph-based parsing algorighms.

```julia-repl
julia> using DependencyTrees.GraphParsing
```

In graph-based dependency parsing, trees are built all at once, rather than greedily (one arc at a time).
A set of possible parses for a sentence is represented by a square matrix of arc weights.
The [`DependencyGraph`](@ref DependencyGraph) type is used for this.

The `DependencyTrees.GraphParsing` module implements the following algorithms:

- [Chu-Liu/Edmonds algorithm](@ref "Chu-Liu/Edmonds algorithm") for decoding a tree
- [Eisner's algorithm](@ref "Eisner's Algorithm") for decoding a projective tree

## Dependency Graphs

```@docs
DependencyGraph
```

## Graph Decoding Algorithms

### Chu-Liu/Edmonds Algorithm

```@docs
chu_liu_edmonds
```

### Eisner's Algorithm

```@docs
eisner
```

## Cycle Detection

### Tarjan's Algorithm

```@docs
DependencyTrees.GraphParsing.tarjan
```
