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

"Projectivity" is a characteristic of dependency trees.

> An arc from a head to a dependent is said to be projective if there is
> a path from the head to every word that lies between the
> headprojective and the dependent in the sentence. A dependency tree is
> then said to be projective if all the arcs that make it up are
> projective. [jm3](@cite)

Drawing the trees will show that non-projective trees have crossing arcs, and projective trees do not.

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
