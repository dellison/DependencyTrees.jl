# Treebanks

A `Treebank` is a corpus of dependency-annotated sentences in one or more files.

```@docs
Treebank
```

Iterating over a treebank reads sentences one at a time:

```jldoctest; setup = :(using DependencyTrees)
treebank = Treebank("data/news.conll")

for tree in treebank
    # ...
end

tree = first(treebank)

# output
┌────────────── ROOT
│           ┌─► Economic
│        ┌─►└── news
└─►┌──┌──└───── had
   │  │     ┌─► little
   │  └─►┌──└── effect
   │  ┌──└────► on
   │  │     ┌─► financial
   │  └────►└── markets
   └──────────► .
```
