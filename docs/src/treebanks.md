# Treebanks

A `Treebank` is a corpus of dependency-annotated sentences in one or more files.

```@docs
Treebank
Treebank(file)
```

Iterating over a treebank reads sentences one at a time:

```jldoctest; setup = :(using DependencyTrees)
treebank = Treebank("data/news.conll", conllu)

for tree in treebank
    # ...
end

tree = first(treebank)

# output
┌────────────── 0 ROOT
│           ┌─► 1 Economic
│        ┌─►└── 2 news
└─►┌──┌──└───── 3 had
   │  │     ┌─► 4 little
   │  └─►┌──└── 5 effect
   │  ┌──└────► 6 on
   │  │     ┌─► 7 financial
   │  └────►└── 8 markets
   └──────────► 9 .
```


## CoNLL-U

```@docs
conllu
```

## CoNLL-X

```@docs
conllx
```
