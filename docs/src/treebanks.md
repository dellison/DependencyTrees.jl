# Treebanks

A `Treebank` is a corpus of dependency-annotated sentences in one or more files.

```@docs
Treebank
```

```jldoctest; setup = :(using DependencyTrees)
treebank = Treebank("data/example.conllu")
tree = first(treebank)

# output
DependencyTree: The cat slept by the window .
```
