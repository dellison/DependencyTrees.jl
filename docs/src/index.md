# DependencyTrees.jl

DependencyTrees.jl is a julia package for working with natural language dependency structures.

## Overview

In the study of natural language, the dependency relation defines a directed relationship between words in a sentence. The `DependencyTrees.jl` package is for working with natural language data annotated with dependency relations, where each sentence forms a [tree](trees.md).

The [`TransitionParsing`](transition_parsing.md) submodule implements some algorithms for transision-based dependency parsing.

## Installation

DependencyTrees is a registered Julia package, and can be installed with Julia's built-in package manager:

```julia-repl
julia> ]add DependencyTrees
julia> using DependencyTrees
```
