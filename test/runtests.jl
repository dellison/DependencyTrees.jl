using DependencyTrees, Test

const DT = DependencyTrees

using DependencyTrees: TreebankReader
using DependencyTrees: projective_only, deptype
using DependencyTrees: deprel, form, id, hashead, head, root, isroot
using DependencyTrees: MultiWordTokenError, EmptyTokenError
using DependencyTrees: si, s, s0, s1, s2, s3, stack
using DependencyTrees: bi, b, b0, b1, b2, b3, buffer
using DependencyTrees: leftmostdep, rightmostdep
using DependencyTrees: leftdeps, rightdeps
using DependencyTrees: root, noval, token, tokens, xys

using DependencyTrees.Parse: typed, untyped
using DependencyTrees.Parse: initconfig, transition_space
using DependencyTrees.Parse: leftarc, rightarc, noarc, shift, isfinal
using DependencyTrees.Parse: LeftArc, RightArc, NoArc, Reduce, Shift
using DependencyTrees.Parse: gold_transitions, zero_cost_transitions
using DependencyTrees.Parse: choose_next_amb, choose_next_exp
using DependencyTrees.Parse: hascost, haszerocost
using DependencyTrees.Parse: xys
using DependencyTrees.Parse: DynamicGoldSearch
using DependencyTrees.Parse: AlwaysExplore, NeverExplore, ExplorationPolicy
using DependencyTrees.Parse: explore, next_state

function showstr(op)
    buf = IOBuffer()
    show(buf, op)
    return String(take!(buf))
end

@testset "DependencyTrees" begin 
    include("test_tokens.jl")
    include("test_graphs.jl")
    include("test_slp3_ch13.jl")
    include("test_nivre08.jl")
    include("test_kubleretal09.jl")
    include("test_treebanks.jl")
    include("test_conllu.jl")
    include("test_dynamic.jl")
    include("test_arc_hybrid.jl")
    include("test_arc_swift.jl")
    include("test_features.jl")
end
