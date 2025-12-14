# Graph Parsing

The `GraphParsing` submodule provides implementations of graph-based parsing algorithms.

```julia-repl
julia> using DependencyTrees.GraphParsing
```

In graph-based dependency parsing, trees are built all at once, predicting a globally best parse from a set of possible ones.
A set of possible parses for a sentence is represented by a square matrix of arc weights: a [`DependencyGraph`](@ref DependencyGraph).

An appealing feature of graph parsing is that jointly predicting the whole tree structure avoids the parser making a "wrong turn" the way that transition parsers can.
The drawback of this is the sacrifice of speed: graph parsing methods are slower than transition parsing methods.

The `DependencyTrees.GraphParsing` module implements the following algorithms:

- [Chu-Liu/Edmonds algorithm](@ref "Chu-Liu/Edmonds Algorithm") for decoding a tree
- [Eisner's algorithm](@ref "Eisner's Algorithm") for decoding a projective tree

## Dependency Graphs

```@docs
DependencyGraph
DependencyGraph(tree::DependencyTree)
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
