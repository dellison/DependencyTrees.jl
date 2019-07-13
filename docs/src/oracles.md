# Oracles

In transition-based dependency parsing, oracles are used to map parser configurations (intermediate parser states) to gold transitions.

[Static](@ref Static-Oracles) and [dynamic](@ref Dynamic-Oracles) oracles can both be used to iterate through trees.

```julia-repl
julia> oracle = DynamicOracle(ArcEager())
julia> for state in oracle(gold_tree)
           # ...
       end
```

`state` here will be a `DependencyTrees.OracleState`, which keeps track of the current configuration, possible transitions, and gold transitions.

```@docs
DependencyTrees.OracleState
```

The iterator itself is something something

```@docs
DependencyTrees.TreeOracle
DependencyTrees.UnparsableTree
```

Both kinds of oracles can build parse trees with labelled (typed) or unlabelled (untyped) dependency relations using the `arc` keyword argument.

```@docs
untyped
typed
```

## Static Oracles

```@docs
StaticOracle
```

### Static Oracle Functions

```@docs
static_oracle
static_oracle_prefer_shift
```

## Dynamic Oracles

```@docs
DynamicOracle
```

### Dynamic Oracle Functions

```@docs
dynamic_oracle
```

## Exploration Policies

Something about exploration during training.

```@docs
AlwaysExplore
NeverExplore
ExplorationPolicy
```
