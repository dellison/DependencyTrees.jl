# DependencyTrees.jl

[![Build Status](https://travis-ci.org/dellison/DependencyTrees.jl.svg?branch=master)](https://travis-ci.org/dellison/DependencyTrees.jl) [![CodeCov](https://codecov.io/gh/dellison/DependencyTrees.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/DependencyTrees.jl)

DependencyTrees.jl is a Julia package for dependency parsing of natural language. It provides implementations of dependency parse structures (`DependencyTree`), a treebank reader, and implementations of several transition systems (including oracles).

Install it with Julia's built-in package manager:

`julia> ]add DependencyTrees`

# Features

## Treebanks and Dependency Trees

The `Treebank{T}` type is a lazy treebank reader, where `T` is the type of the nodes in the graph. Supported dependency types:

- `UntypedDependency`
- `TypedDependency`
- `CoNLLU` (see [universaldependencies.org](https://universaldependencies.org/))

```julia
julia> treebank = Treebank{CoNLLU}("/path/to/treebank.conllu")
julia> for tree in treebank
           # ...
       end
```

## Transition-Based Dependency Parsing

DependencyTrees.jl implements the following transition systems:

* `ArcStandard` (supports `StaticOracle`)
* `ArcEager`[1],[2] (supports `StaticOracle` and `DynamicOracle`)
* `ArcHybrid`[3],[4] (supports `StaticOracle` and `DynamicOracle`)
* `ArcSwift`[5] (supports `StaticOracle`)
* `ListBasedNonProjective`[2] (supports `StaticOracle`)

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

## Contributing & Help

[Open an issue](https://github.com/dellison/DependencyTrees.jl/issues/new)! Bug reports, feature requests, etc. are all welcome. 

## References

[1]: Nivre 2003: An efficient algorithm for dependency parsing. http://stp.lingfil.uu.se/~nivre/docs/iwpt03.pdf

[2]: Nivre 2008: Algorithms for Deterministic Incremental Dependency Parsing. https://www.aclweb.org/anthology/J/J08/J08-4003.pdf

[3]: Kuhlmann et all 2011: Dynamic programming algorithms for transition-based dependency parsers. https://www.aclweb.org/anthology/P/P11/P11-1068.pdf

[4]: Goldberg & Nivre 2013: Training deterministic parsers with non-deterministic oracles. https://aclweb.org/anthology/Q/Q13/Q13-1033.pdf

[5]: Qi & Manning 2016: Arc-swift: a novel transition system for dependency parsing. https://nlp.stanford.edu/pubs/qi2017arcswift.pdf
