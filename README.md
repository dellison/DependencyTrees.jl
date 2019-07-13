# DependencyTrees.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://dellison.github.io/DependencyTrees.jl/stable) [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://dellison.github.io/DependencyTrees.jl/dev)

[![Build Status](https://travis-ci.org/dellison/DependencyTrees.jl.svg?branch=master)](https://travis-ci.org/dellison/DependencyTrees.jl) [![CodeCov](https://codecov.io/gh/dellison/DependencyTrees.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/DependencyTrees.jl)

DependencyTrees.jl is a Julia package for working with natural language sentence annotated with dependency structure. It provides implementations of dependency parse trees (`DependencyTree`), a treebank reader, and implementations of several transition systems with oracles.

Install it with Julia's built-in package manager:

```julia
julia> ]add DependencyTrees
```

## Features

### Trees and Treebanks

```julia-repl
julia> using DependencyTrees

julia> treebank = Treebank("path/to/trees.conll")
julia> for tree in treebank
           # ...
	   end
```

### Transition-based parsing

```julia-repl
julia> using DependencyTrees

julia> treebank = Treebank("path/to/trees.conll")
julia> oracle = DynamicOracle(ArcHybrid())
julia> for tree in treebank
           for state in oracle(tree)
		       cfg, possible_arcs, gold_arcs = state.cfg, state.A, state.G
			   # ...
		   end
	   end
```

Transition systems:

* `ArcStandard` (static oracle)
* `ArcEager`<sup>[1],[2]</sup> (static and dynamic oracles)
* `ArcHybrid`<sup>[3],[4]</sup> (static and dynamic oracles)
* `ArcSwift`<sup>[5]</sup> (static oracle)
* `ListBasedNonProjective`<sup>[2]</sup> (static oracle)

## Contributing & Help

[Open an issue](https://github.com/dellison/DependencyTrees.jl/issues/new)! Bug reports, feature requests, etc. are all welcome. 

## References

[1]: Nivre 2003: An efficient algorithm for projective dependency parsing. http://stp.lingfil.uu.se/~nivre/docs/iwpt03.pdf

[2]: Nivre 2008: Algorithms for Deterministic Incremental Dependency Parsing. https://www.aclweb.org/anthology/J/J08/J08-4003.pdf

[3]: Kuhlmann et all 2011: Dynamic programming algorithms for transition-based dependency parsers. https://www.aclweb.org/anthology/P/P11/P11-1068.pdf

[4]: Goldberg & Nivre 2013: Training deterministic parsers with non-deterministic oracles. https://aclweb.org/anthology/Q/Q13/Q13-1033.pdf

[5]: Qi & Manning 2016: Arc-swift: a novel transition system for dependency parsing. https://nlp.stanford.edu/pubs/qi2017arcswift.pdf
