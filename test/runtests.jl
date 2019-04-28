using DependencyTrees, Test

using DependencyTrees: TreebankReader

using DependencyTrees.Parse: initconfig, transition_space
using DependencyTrees.Parse: leftarc, rightarc, noarc, shift, isfinal
using DependencyTrees.Parse: LeftArc, RightArc, NoArc, Reduce, Shift
using DependencyTrees.Parse: gold_transitions, zero_cost_transitions
using DependencyTrees.Parse: choose_next_amb, choose_next_exp
using DependencyTrees.Parse: hascost, haszerocost
using DependencyTrees.Parse: OnlineTrainer, train!, xys
using DependencyTrees.Parse: DynamicGoldSearch
using DependencyTrees.Parse: AlwaysExplore, NeverExplore, ExplorationPolicy
using DependencyTrees.Parse: explore, next_state

const DT = DependencyTrees

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
