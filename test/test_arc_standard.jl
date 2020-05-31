@testset "Arc-Standard" begin

    tree = deptree(x -> deptoken(x[1], x[2]), [
        ("the", 2),
        ("cat", 3),
        ("slept", 0),
        ("on", 3),
        ("the", 6),
        ("bed", 4)
    ])

    @testset "Static" begin
        oracle = Oracle(ArcStandard(), static_oracle)
        for (cfg, t) in oracle(tree)
            @test t in possible_transitions(cfg)
        end
        @test initconfig(oracle, tree) == initconfig(oracle, tree)
    end
end
