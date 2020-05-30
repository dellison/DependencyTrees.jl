@testset "Tokens" begin

    using DependencyTrees: Token, has_head

    @testset "Untyped Dependencies" begin
        sent = [
            ("The", 2),
            ("cat", 3),
            ("slept", 0),
            (".", 3)
        ]
        for (i, word) in enumerate(sent)
            form, head = word
            token = Token(form, head, id=i)
            @test token.form == form
            @test token.id == i
            @test token.head == head
        end
        @test !has_head(Token())
        @test !has_head(Token("hi"))
    end

    @testset "Typed Dependencies" begin
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
        end
    end

    @testset "Multi-headed tokens" begin
        t = Token("hi", (0, 2))
        @test has_head(t)
        @test has_head(t, 0)
        @test has_head(t, 2)
        @test !has_head(t, 1)
        @test DependencyTrees.headisroot(t)
    end

    @testset "Errors" begin
        t = Token("hi")
        @test_throws Exception t.x
        tx = Token("hi"; x="x")
        @test tx.x == "x"
    end
end
