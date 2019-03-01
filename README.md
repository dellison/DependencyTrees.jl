# DependencyTrees.jl

[![Build Status](https://travis-ci.org/dellison/DependencyTrees.jl.svg?branch=master)](https://travis-ci.org/dellison/DependencyTrees.jl) [![CodeCov](https://codecov.io/gh/dellison/DependencyTrees.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/DependencyTrees.jl)

DependencyTrees.jl is a Julia package for dependency parsing of natural language. It provide implementations of dependency parse structures (`DependencyTree`), a treebank reader, and implementations of a number of transition systems (including oracles).

# Features

## Treebanks and Dependency Graphs

The `Treebank{T}` (parametric) type is a lazy treebank reader, where `T` is the type of the nodes in the graph. Supported dependency types:

- `UntypedDependency`
- `TypedDependency`
- `CoNLLU` (see [universaldependencies.org](https://universaldependencies.org/))

## Transition-Based Dependency Parsing

DependencyTrees.jl implements a number of transition systems:

* `ArcStandard` (supports `StaticOracle`)
* `ArcEager` (supports `StaticOracle` and `DynamicOracle`)
* `ArcHybrid` (supports `StaticOracle` and `DynamicOracle`)
* `ArcSwift` (supports `StaticOracle`)
* `ListBasedNonProjective` (supports `StaticOracle`)

### Oracles

Oracles map parser configurations to one or more gold transitions.

Static Oracles are deterministic, mapping each parser configurations to a single gold transition.

```julia
julia> using DependencyTrees

julia> tb = Treebank{CoNLLU}("/path/to/traindata.conllu")
julia> oracle = StaticOracle(ArcEager())
julia> for (cfg, gold_t) in DependencyTrees.xys(oracle, tb)
           # ...
       end
```

Dynamic Oracles map parser configurations to sets of gold transitions.

```julia
julia> oracle = DynamicOracle(ArcHybrid())
julia> for (cfg, gold_ts) in DependencyTrees.xys(oracle, tb)
           # ...
       end
```

The `LeftArc` and `RightArc` transition operations can be either typed (e.g., `LeftArc("nsubj")`), or untyped (e.g., `LeftArc()`), depending on the `transition` keyword argument passed to the oracle. Typed transitions are default. `DependencyTrees.typed` and `DependencyTrees.untyped` work as described here, but it's also possible to write functions to parameterize these transitions in arbitrary ways.

