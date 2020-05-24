# Transition Parsing

The `TransitionParsing` submodule provides implementations of transition-based parsing algorighms.

```julia-repl
julia> using DependencyTrees.TransitionParsing
```

In transition-based dependency parsing, trees are built incrementally and greedily, one relation at a time.
Transition systems define an intermediate parser state (or configuration), and oracles map confifurations to "gold" transitions.

The `DependencyTrees.TransitionParsing` module implements the following transition systems:

- [Arc-Standard](@ref Arc-Standard)
- [Arc-Eager](@ref Arc-Eager)
- [Arc-Hybrid](@ref Arc-Hybrid)
- [Arc-Swift](@ref Arc-Swift)
- [List-Based Non-Projective](@ref List-Based-Non-Projective)

## Arc-Standard

```@docs
ArcStandard
```

Oracle function for arc-standard parsing:

```@docs
static_oracle(::TransitionParsing.ArcStandardConfig, tree, arc=untyped)
```

## Arc-Eager

```@docs
ArcEager
```

Oracle functions for arc-eager parsing:

```@docs
static_oracle(::TransitionParsing.ArcEagerConfig, tree, arc=untyped)
static_oracle_prefer_shift(::TransitionParsing.ArcEagerConfig, tree, arc=untyped)
dynamic_oracle(cfg::TransitionParsing.ArcEagerConfig, tree, arc=untyped)
```

## Arc-Hybrid

```@docs
ArcHybrid
```

Oracle functions for arc-hybrid parsing:

```@docs
static_oracle(::TransitionParsing.ArcHybridConfig, tree, arc=untyped)
dynamic_oracle(t, cfg::TransitionParsing.ArcHybridConfig, tree)
```

## Arc-Swift

```@docs
ArcSwift
```

Oracle function for arc-swift parsing:

```@docs
static_oracle(::TransitionParsing.ArcSwiftConfig, gold, arc=untyped)
```

## List-Based Non-Projective

```@docs
ListBasedNonProjective
```

Oracle function for list-based non-projective parsing:

```@docs
static_oracle(::TransitionParsing.ListBasedNonProjectiveConfig, tree, arc=untyped)
```

<!-- ## Misc. -->

<!-- For stack-and-buffer transition systems ([Arc-Eager](@ref Arc-Eager), [Arc-Standard](@ref Arc-Standard), [Arc-Hybrid](@ref Arc-Hybrid), and [Arc-Swift](@ref Arc-Swift)), DependencyTrees.jl implements functions for getting the tokens from the stack and buffer in a safe way: -->

<!-- ```@docs -->
<!-- stacktoken -->
<!-- buffertoken -->
<!-- ``` -->

## Oracles

An `Oracle` maps a parser configuration to one more gold transitions, which can be used to train a dependency parser.

```@docs
Oracle
```

An oracle acts like a function when called on a `DependencyTree`, returning either an `OracleSequence` or an `UnparsableTree` in the case when a tree cannot be parsed.


```@docs
TransitionParsing.OracleSequence
TransitionParsing.UnparsableTree
```

An `Oracle`'s third argument is a function called on a `DependencyTrees.Token` to parametrize a transition.
This parameterization can be arbitrary, but `DependencyTrees.TransitionParsing` exports two function which yield labeled or unlabeled dependencies, respectively:

```@docs
untyped
typed
```

### Exploration Policies

Training a parser on only optimal sequeces of transitions can result in poor decisions under suboptimal conditions (i.e., after a mistake has been made).
To compensate for this, `OracleSequence`s can be created with *exploration policies* to control when (if ever) a "wrong" transition that prevents the correct parse from being produced is allowed.

Exploration policies can wrap a `model`, which will be called to predict a transition (called like `model(cfg, A, G)` where `cfg` is the parser configuration, `A` is a vector of possible transitions, and `G` is the `gold` transition(s) according to the oracle function).
The exploration policy then selects the next transition from `A` and `G` and the prediction, if available.


```@docs
AlwaysExplore
NeverExplore
ExplorationPolicy
```
