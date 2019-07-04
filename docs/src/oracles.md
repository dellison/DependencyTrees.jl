# Oracles

In transition-based dependency parsing, oracles are used to map parser configurations (intermediate parser states) to gold transitions.

[Static](@ref Static-Oracles) and [Dynamic](@ref Dynamic-Oracles) oracles can both be used to iterate through trees.

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

## Static Oracles

```@docs
StaticOracle
```

## Dynamic Oracles

```@docs
DynamicOracle
```

### Exploration Policies

Something about exploration during training.

```@docs
AlwaysExplore
NeverExplore
ExplorationPolicy
```
