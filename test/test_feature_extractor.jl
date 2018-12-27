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


    @testset "Features for a linear model" begin
        fx = DependencyTrees.@feature_extractor cfg begin
            s0 = DependencyTrees.s0(cfg)
            s0_form = "s0.form:$(s0.form)"
            s0_upos = "s0.upos:$(s0.upos)"

            b = DependencyTrees.b(cfg)
            b_form = "b.form:$(b.form)"
            b_upos = "b.upos:$(b.upos)"

            # features
            ("bias",)
            (s0_form,)
            (s0_upos,)
            (s0_form, s0_upos)
            (b_form,)
            (b_upos,)
            (b_form, b_upos)
        end

        for T in (ArcHybrid, ArcEager, ArcStandard, ArcSwift)

            cfg = T(tree)
            features = fx(cfg)

            @test ("bias",) in features
            @test ("s0.form:ROOT",) in features
            @test ("s0.upos:ROOT",) in features
            @test ("s0.form:ROOT","s0.upos:ROOT") in features

            @test ("b.form:Economic",) in features
            @test ("b.upos:_",) in features
            @test ("b.form:Economic", "b.upos:_") in features

            @test !(("notpresent",) in features)
        end
    end

    @testset "Neural-style feature extractor" begin
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
