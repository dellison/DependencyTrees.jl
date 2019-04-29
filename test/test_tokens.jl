struct Deplol <: DT.Dependency end

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
            @test deprel(dep) == ()
            @test form(dep) == token[1]
            @test id(dep) == i
            @test !isroot(dep)
            @test head(dep) == token[2]
            @test untyped(dep) == typed(dep) == ()
        end
        @test !hashead(noval(UntypedDependency))
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
            @test untyped(dep) == ()
            @test typed(dep) == (token[2],)
        end
        @test !hashead(noval(TypedDependency))
    end

    @testset "Errors" begin
        d = Deplol()
        function check_error(fn, d)
            try
                fn(d)
                @test false
            catch err
                @test occursin("not implemented", err.msg)
            end
        end
        check_error(DT.dep, d)
        check_error(DT.deprel, d)
        check_error(DT.form, d)
        check_error(DT.hashead, d)
        check_error(DT.head, d)
        check_error(DT.isroot, d)
        check_error(DT.noval, d)
        check_error(DT.root, Deplol)
        check_error(DT.unk, Deplol)
    end
end
