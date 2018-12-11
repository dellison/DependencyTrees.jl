using DependencyTrees: TreebankReader

@testset "Dynamic Oracle" begin

    error_cb(args...) = nothing
    
    C = ArcEager{TypedDependency}
    oracle = DynamicOracle(C)
    
    model(cfg) = nothing
    
    trainer = OnlineTrainer(oracle, model, identity, error_cb)

    sent = [
        ("Economic", "NMOD", 2),  # 1
        ("news", "SUBJ", 3),      # 2
        ("had", "ROOT", 0),       # 3
        ("little", "NMOD", 5),    # 4
        ("effect", "OBJ", 3),     # 5
        ("on", "NMOD", 5),        # 6
        ("financial", "NMOD", 8), # 7
        ("markets", "PMOD", 6),   # 8
        (".", "P", 3),            # 9
    ]

    graph = DependencyGraph(TypedDependency, sent, add_id=true)
    DependencyTrees.train!(trainer, graph)

    model = static_oracle(ArcEager{TypedDependency}, graph)
    function error_cb(x, ŷ, y)
        @assert false
    end
    trainer = OnlineTrainer(oracle, model, identity, error_cb)
    DependencyTrees.train!(trainer, graph)

    cfg = DependencyTrees.initconfig(oracle.config, graph)
    while !isfinal(cfg)
        pred = model(cfg)
        gold = DependencyTrees.zero_cost_transitions(cfg, graph)
        @test pred in gold
        cfg = pred(cfg)
    end

    trainer = OnlineTrainer(oracle, x -> nothing, identity, (args...) -> nothing)
    tbfile = joinpath(@__DIR__, "data", "wsj_0001.dp")
    treebank = collect(TreebankReader{TypedDependency}(tbfile, add_id=true))
    for tree in treebank
        DependencyTrees.train!(trainer, tree)
    end
end
