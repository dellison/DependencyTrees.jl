# DependencyTrees.jl

[![Build Status](https://travis-ci.org/dellison/DependencyTrees.jl.svg?branch=master)](https://travis-ci.org/dellison/DependencyTrees.jl) [![CodeCov](https://codecov.io/gh/dellison/DependencyTrees.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/DependencyTrees.jl)

DependencyTrees.jl is a Julia package for dependency parsing of natural language. It provide implementations of dependency graphs, a treebank reader, and implementations of a number of transition systems (including oracles).

## Features

### Treebanks and Dependency Graphs

### Transition-Based Dependency Parsing

DependencyTrees.jl implements a number of transition systems:

* `ArcStandard` (supports `StaticOracle`)
* `ArcEager` (supports `StaticOracle` and `DynamicOracle`)
* `ArcHybrid` (supports `StaticOracle` and `DynamicOracles`)
* `ArcSwift` (supports `StaticOracle`)
* `ListBasedNonProjective` (supports `StaticOracle`)

#### Oracles

Oracles are used to map a configuration (parser state) to one (`StaticOracle`) or more (`DynamicOracle`) gold transitions.

```julia
julia> using DependencyTrees

julia> tb = Treebank{CoNLLU}("/path/to/traindata.conllu")
julia> oracle = StaticOracle(ArcEager())
julia> for (cfg, gold_t) in xys(oracle, tb)
           # ...
       end
```
