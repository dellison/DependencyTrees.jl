# Trees

Dependency structure in natural language consists of directed relations between words in a sentence.

Simple API for building dependency trees:

```@docs
DependencyTree
```

## DependencyTree functions

```@docs
DependencyTrees.arcs
```

## Projectivity

```@docs
DependencyTrees.isprojective
```

## Tokens

```@docs
DependencyTrees.Token
```

## Visualizing Trees

DependencyTrees.jl by default displays `DependencyTree`s by drawing arrows representing the dependency arcs.
For example, 
