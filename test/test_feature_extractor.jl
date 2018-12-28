@testset "Feature Extraction" begin

    tree = DependencyGraph{CoNLLU}("""
    1	Economic	economic	_	_	_	2	att	_	_
    2	news	news	_	_	_	3	sbj	_	_
    3	had	had	_	_	_	0	pred	_	_
    4	little	little	_	_	_	5	att	_	_
    5	effect	effect	_	_	_	3	obj	_	_
    6	on	on	_	_	_	5	att	_	_
    7	financial	financial	_	_	_	8	att	_	_
    8	markets	markets	_	_	_	6	pc	_	_
    9	.	pu	_	_	_	3	pu	_	_
    """)


    @testset "Feature Templates" begin

        featurize = DependencyTrees.@feature_template_extractor cfg begin
            s0 = DependencyTrees.s0(cfg)
            b = DependencyTrees.b(cfg)

            # features
            ("bias",)
            (s0.form,)
            (s0.upos,)
            (s0.form, s0.upos)
            (b.form,)
            (b.upos,)
            (b.form, b.upos)
        end

        for T in (ArcHybrid, ArcEager, ArcStandard, ArcSwift)

            cfg = T(tree)

            features = featurize(cfg)
            @test "bias" in features
            @test ("s0.form", "ROOT") in features
            @test ("s0.upos", "ROOT") in features
            @test ("s0.form", "ROOT", "s0.upos", "ROOT") in features
            @test ("b.form", "Economic") in features
            @test ("b.upos", "_") in features
            @test ("b.form", "Economic", "b.upos", "_") in features

        end
    end

    @testset "Ordered features" begin
        fx = DependencyTrees.@feature_extractor cfg begin
            s2 = DependencyTrees.s2(cfg)
            s1 = DependencyTrees.s1(cfg)
            s0 = DependencyTrees.s0(cfg)
            b = DependencyTrees.b(cfg)
            b2 = DependencyTrees.b2(cfg)
            b3 = DependencyTrees.b3(cfg)
            
            (s2.form, s1.form, s0.form, b.form, b2.form, b3.form)
        end

        for T in (ArcHybrid, ArcEager, ArcStandard, ArcSwift)

            cfg = T(tree)
            features = fx(cfg)

            @test features == ("NOVAL", "NOVAL", "ROOT", "Economic", "news", "had")
        end
    end
end
