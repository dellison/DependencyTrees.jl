using DependencyTrees: deprel, form, id, head, root, isroot

struct Deplol <: DependencyTrees.Dependency end

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
            @test DependencyTrees.untyped(dep) == DependencyTrees.typed(dep) == ()
        end

        noval = DependencyTrees.noval(UntypedDependency)
        @test !DependencyTrees.hashead(noval)
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
            @test DependencyTrees.untyped(dep) == ()
            @test DependencyTrees.typed(dep) == (token[2],)
        end

        noval = DependencyTrees.noval(TypedDependency)
        @test !DependencyTrees.hashead(noval)
    end

    @testset "Errors" begin
        d = Deplol()
        function check_error(fn, d)
            try
                fn(d)
                @test false
            catch err
                # @show err
                @test occursin("not implemented", err.msg)
            end
        end
        check_error(DependencyTrees.dep, d)
        check_error(DependencyTrees.deprel, d)
        check_error(DependencyTrees.form, d)
        check_error(DependencyTrees.hashead, d)
        check_error(DependencyTrees.head, d)
        check_error(DependencyTrees.isroot, d)
        check_error(DependencyTrees.noval, d)
        check_error(DependencyTrees.root, Deplol)
        check_error(DependencyTrees.unk, Deplol)
    end
end
