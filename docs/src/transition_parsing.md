# Transition Systems

## Arc-Standard

```@docs
ArcStandard
```

Static oracle function:

```@docs
static_oracle(::DependencyTrees.ArcStandardConfig, tree, arc)
```

## Arc-Eager

```@docs
ArcEager
```
### Static oracle functions

```@docs
static_oracle(::DependencyTrees.ArcEagerConfig, tree, arc)
static_oracle_prefer_shift(::DependencyTrees.ArcEagerConfig, tree, arc)
```

### Dynamic oracle functions

```@docs
dynamic_oracle(t, cfg::DependencyTrees.ArcEagerConfig, tree)
```

## Arc-Hybrid

```@docs
ArcHybrid
```

Static oracle function:

```@docs
static_oracle(::DependencyTrees.ArcHybridConfig, tree, arc)
```

### Dynamic oracle functions

```@docs
dynamic_oracle(t, cfg::DependencyTrees.ArcHybridConfig, tree)
```

## Arc-Swift

```@docs
ArcSwift
```

Static oracle function:

```@docs
static_oracle(::DependencyTrees.ArcSwiftConfig, tree, arc)
```

## List-Based Non-Projective

```@docs
ListBasedNonProjective
```

Static oracle function:

```@docs
static_oracle(::DependencyTrees.ListBasedNonProjectiveConfig, tree, arc)
```
