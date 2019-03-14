# DependencyTrees.jl

[![Build Status](https://travis-ci.org/dellison/DependencyTrees.jl.svg?branch=master)](https://travis-ci.org/dellison/DependencyTrees.jl) [![CodeCov](https://codecov.io/gh/dellison/DependencyTrees.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/DependencyTrees.jl)

DependencyTrees.jl is a Julia package for dependency parsing of natural language. It provides implementations of dependency parse structures (`DependencyTree`), a treebank reader, and implementations of several transition systems (including oracles).

Install it with Julia's built-in package manager:

```julia
julia> ]add DependencyTrees
```

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
* `ArcEager`<sup>[1],[2]</sup> (supports `StaticOracle` and `DynamicOracle`)
* `ArcHybrid`<sup>[3],[4]</sup> (supports `StaticOracle` and `DynamicOracle`)
* `ArcSwift`<sup>[5]</sup> (supports `StaticOracle`)
* `ListBasedNonProjective`<sup>[2]</sup> (supports `StaticOracle`)

### Oracles

Oracles map parser configurations to one or more gold transitions. In other words, they provide a way to transform any well-formed dependency tree into a series of (x, y) pairs. 

The interface for oracles is `DependencyTrees.xys(oracle, data)`, which returns a lazy iterator over one or more gold dependency trees.

#### Static Oracles

Static Oracles are deterministic, mapping each parser configurations to a single gold transition.

```julia
julia> using DependencyTrees

julia> tb = Treebank{CoNLLU}("/path/to/traindata.conllu")
julia> oracle = StaticOracle(ArcEager())
julia> for (cfg, gold_t) in DependencyTrees.xys(oracle, tb)
           # ...
       end
```

#### Dynamic Oracles

Dynamic Oracles map parser configurations to sets of gold transitions.

```julia
julia> oracle = DynamicOracle(ArcHybrid())
julia> for (cfg, gold_ts) in DependencyTrees.xys(oracle, tb)
           # ...
       end
```

#### Typed and Untyped Dependency Arcs

The `LeftArc` and `RightArc` transition operations can be either typed (e.g., `LeftArc("nsubj")`), or untyped (e.g., `LeftArc()`), depending on the `transition` keyword argument passed to the oracle. Typed transitions are default. `DependencyTrees.typed` and `DependencyTrees.untyped` work as described here, but it's also possible to write functions to parameterize these transitions in arbitrary ways.

```julia
julia> # example oracles
julia> oracle = StaticOracle(ArcEager(), transition=DependencyTrees.typed)
julia> oracle = DynamicOracle(ArcHybrid(), transition=DependencyTrees.untyped)
```

Transition systems vary on their support for nonprojective trees, so it's common to filter a treebank ahead of time to remove nonprojective trees for certain transition systems. `StaticOracle`s and `DynamicOracle`s will automatically skip nonprojective trees for projective-only transition systems when iterating over treebanks, so this step can be skipped.

## Contributing & Help

[Open an issue](https://github.com/dellison/DependencyTrees.jl/issues/new)! Bug reports, feature requests, etc. are all welcome. 

## References

[1]: Nivre 2003: An efficient algorithm for projective dependency parsing. http://stp.lingfil.uu.se/~nivre/docs/iwpt03.pdf

[2]: Nivre 2008: Algorithms for Deterministic Incremental Dependency Parsing. https://www.aclweb.org/anthology/J/J08/J08-4003.pdf

[3]: Kuhlmann et all 2011: Dynamic programming algorithms for transition-based dependency parsers. https://www.aclweb.org/anthology/P/P11/P11-1068.pdf

[4]: Goldberg & Nivre 2013: Training deterministic parsers with non-deterministic oracles. https://aclweb.org/anthology/Q/Q13/Q13-1033.pdf

[5]: Qi & Manning 2016: Arc-swift: a novel transition system for dependency parsing. https://nlp.stanford.edu/pubs/qi2017arcswift.pdf
