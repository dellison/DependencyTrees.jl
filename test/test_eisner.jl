@testset "Eisner's Algorithm" begin

    @testset "The plan of the government to raise income tax" begin

        tree = DependencyTree([# ┌────────────── 0 ROOT
            ("the", 2)         # │           ┌─► 1 the
            ("plan", 0)        # └─►┌─────┌──└── 2 plan
            ("of", 2)          #    │  ┌──└────► 3 of
            ("the", 5)         #    │  │     ┌─► 4 the
            ("government", 3)  #    │  └────►└── 5 government
            ("to", 7)          #    │        ┌─► 6 to
            ("raise", 2)       #    └────►┌──└── 7 raise
            ("income", 9)      #          │  ┌─► 8 income
            ("tax", 7)         #          └─►└── 9 tax
        ])

        using DependencyTrees.GraphParsing
    
        G = DependencyGraph(tree)
    
        decoded_tree, score = GraphParsing.eisner(G)

        @test score == 9.0 # 9 arcs

        using DependencyTrees: arcs
        @test arcs(decoded_tree) == arcs(tree)

    end

    @testset "Decoding random trees" begin

        using DependencyTrees: isprojective
        using DependencyTrees.GraphParsing

        @test all(1:1000) do _
            n = rand(10:30)
            G = rand(n, n)
            tree, score = eisner(G)
            isprojective(tree)
        end
    end
end
