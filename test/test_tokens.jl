using DependencyTrees: deprel, form, id, head, root, isroot

@testset "Tokens" begin

    @testset "Untyped Dependencies" begin
        r = root(UntypedDependency)
        @test isroot(r)
        sent = [
            ("The", 2),
            ("cat", 3),
            ("slept", 0),
            (".", 3)
        ]
        for (i, token) in enumerate(sent)
            dep = UntypedDependency(i, token...)
            @test deprel(dep) == nothing
            @test form(dep) == token[1]
            @test id(dep) == i
            @test !isroot(dep)
            @test head(dep) == token[2]
        end
    end

    @testset "Typed Dependencies" begin
        r = root(TypedDependency{String})
        @test isroot(r)
        @test isroot(root(TypedDependency))
        sent = [
            ("The", "DT", 2),
            ("cat", "NN", 3),
            ("slept", "VBD", 0),
            (".", ".", 3)
        ]
        for (i, token) in enumerate(sent)
            dep = TypedDependency(i, token...)
            @test form(dep) == token[1]
            @test deprel(dep) == token[2]
            @test head(dep) == token[3]
            @test id(dep) == i
            @test !isroot(dep)
        end
    end
end
