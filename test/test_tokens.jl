# struct Deplol <: DT.Dependency end

@testset "Tokens" begin

    using DependencyTrees: Token

    @testset "Untyped Dependencies" begin
        # r = root(UntypedDependency)
        # @test isroot(r)
        sent = [
            ("The", 2),
            ("cat", 3),
            ("slept", 0),
            (".", 3)
        ]
        for (i, word) in enumerate(sent)
            form, head = word
            token = Token(form, head, id=i)
            # @test deprel(dep) == ()
            @test token.form == form
            @test token.id == i
            # @test !isroot(dep)
            @test token.head == head
            # @test untyped(dep) == typed(dep) == ()
        end
        # @test !hashead(noval(UntypedDependency))
    end

    @testset "Typed Dependencies" begin
        # r = root(TypedDependency{String})
        # @test isroot(r)
        # @test isroot(root(TypedDependency))
        sent = [
            ("The", "DT", 2),
            ("cat", "NN", 3),
            ("slept", "VBD", 0),
            (".", ".", 3)
        ]
        for (i, word) in enumerate(sent)
            form, deprel, head = word
            token = Token(form, head, deprel=deprel, id=i)
            @test token.form == form
            @test token.deprel == deprel
            @test token.head == head
            @test token.id == i
            # @test !isroot(dep)
            # @test untyped(dep) == ()
            # @test typed(dep) == (token[2],)
        end
        # @test !hashead(noval(TypedDependency))
    end

    @testset "Errors" begin
        # d = Deplol()
        # function check_error(fn, d)
        #     try
        #         fn(d)
        #         @test false
        #     catch err
        #         @test occursin("not implemented", err.msg)
        #     end
        # end
        # check_error(DT.dep, d)
        # check_error(DT.deprel, d)
        # check_error(DT.form, d)
        # check_error(DT.hashead, d)
        # check_error(DT.head, d)
        # check_error(DT.isroot, d)
        # check_error(DT.noval, d)
        # check_error(DT.root, Deplol)
        # check_error(DT.unk, Deplol)
    end
end
