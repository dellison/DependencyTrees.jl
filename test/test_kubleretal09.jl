using DependencyTrees, Test

using DependencyTrees: shift, leftarc, rightarc, reduce
using DependencyTrees: LeftArc, RightArc, Shift, Reduce
using DependencyTrees: isfinal, train!

# tests from sandra kubler, ryan mcdonald, joakim nivre 09 "dependency
# parsing" (https://doi.org/10.2200/S00169ED1V01Y200901HLT002)

@testset "Kübler et al 09" begin

    fig_1_1 = [
        ("Economic", "ATT", 2),
        ("news", "SBJ", 3),
        ("had", "PRED", 0),
        ("little", "ATT", 5),
        ("effect", "OBJ", 3),
        ("on", "ATT", 5),
        ("financial", "ATT", 8),
        ("markets", "PC", 6),
        (".", "PU", 3),
    ]

    graph = DependencyGraph(TypedDependency, fig_1_1, add_id=true)
    @test length(graph) == length(fig_1_1)

    @testset "Figure 3.7" begin
        sent = first.(fig_1_1)

        graph = DependencyGraph(TypedDependency, fig_1_1, add_id=true)

        oracle = DependencyTrees.static_oracle(ArcEager, graph)

        init = ArcEager{TypedDependency}(sent)
        @test init.σ == [0] && init.β == 1:9

        config = ArcEager{TypedDependency}(sent)

        gold_transitions = [Shift()
                            LeftArc("ATT")
                            Shift()
                            LeftArc("SBJ")
                            RightArc("PRED")
                            Shift()
                            LeftArc("ATT")
                            RightArc("OBJ")
                            RightArc("ATT")
                            Shift()
                            LeftArc("ATT")
                            RightArc("PC")
                            Reduce()
                            Reduce()
                            Reduce()
                            RightArc("PU")]

        for t in gold_transitions
            @test !isfinal(config)
            @test oracle(config) == t
            config = t(config)
        end
        @test isfinal(config)
        graph2 = DependencyGraph(config.A)
        @test graph == graph2

        graph3 = DependencyTrees.parse(ArcEager{TypedDependency}, sent, oracle)
        @test graph3 == graph2

        oracle = StaticOracle(ArcEager{TypedDependency})
        pairs = xys(oracle, graph)
        @test collect(last.(pairs)) == gold_transitions
        @test collect(xys(oracle, [graph])) == collect(pairs)

        model = static_oracle(oracle.config, graph) # perfect model for this sentence
        trainer = OnlineTrainer(oracle, model, identity, (x, ŷ, y) -> error("oracle was wrong"))
        train!(trainer, graph)
    end

    @testset "Features" begin

        # Table 3.2
        fx = DependencyTrees.@feature_template (cfg, gold) begin
            s0 = DependencyTrees.s0(cfg)
            s1 = DependencyTrees.s1(cfg)
            ldep_s0 = DependencyTrees.leftmostdep(cfg, s0)
            rdep_s0 = DependencyTrees.rightmostdep(cfg, s0)
            b0 = DependencyTrees.b(cfg)
            b1 = DependencyTrees.b2(cfg)
            b2 = DependencyTrees.b3(cfg)
            b3 = DependencyTrees.bi(cfg, 4)
            ldep_b0 = DependencyTrees.leftmostdep(cfg, b0)
            rdep_b0 = DependencyTrees.rightmostdep(cfg, b0)
            # feature set:
            ("bias",)
            (s0.form,); (s0.lemma,); (s0.upos,); (s0.feats,)
            (s1.upos,)
            (ldep_s0.deprel,); (rdep_s0.deprel,)
            (b0.form,); (b0.lemma,); (b0.upos,); (b0.feats,)
            (b1.form,); (b1.upos,)
            (b2.upos,)
            (b3.upos,)
            (ldep_b0.deprel,)
            (rdep_b0.deprel,)
        end

        tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "english.conllu"))

        for T in (ArcEager, ArcStandard, ArcHybrid, ArcSwift)

            graph = first(tb)
            cfg = ArcEager(graph)

            features = fx(cfg, graph)
            @test "s0.form=ROOT" in features
            @test "s0.lemma=ROOT" in features
            @test "s0.upos=ROOT" in features
            @test "s0.feats=_" in features
            @test "s1.upos=NOVAL" in features
            @test "ldep_s0.deprel=NOVAL" in features
            @test "rdep_s0.deprel=NOVAL" in features
            @test "b0.form=From" in features
            @test "b0.lemma=_" in features
            @test "b0.upos=ADP" in features
            @test "b0.feats=_" in features
            @test "b1.form=the" in features
            @test "b1.upos=DET" in features
            @test "b2.upos=PROPN" in features
            @test "b3.upos=VERB" in features
            @test "ldep_b0.deprel=NOVAL" in features
            @test "rdep_b0.deprel=NOVAL" in features

            graph = last(collect(tb))
            cfg = ArcEager(graph)

            features = fx(cfg, graph)
            @test "s0.form=ROOT" in features
            @test "s0.lemma=ROOT" in features
            @test "s0.upos=ROOT" in features
            @test "s0.feats=_" in features
            @test "s1.upos=NOVAL" in features
            @test "ldep_s0.deprel=NOVAL" in features
            @test "rdep_s0.deprel=NOVAL" in features
            @test "b0.form=President" in features
            @test "b0.lemma=_" in features
            @test "b0.upos=PROPN" in features
            @test "b0.feats=_" in features
            @test "b1.form=Bush" in features
            @test "b1.upos=PROPN" in features
            @test "b2.upos=ADP" in features
            @test "b3.upos=PROPN" in features
            @test "ldep_b0.deprel=NOVAL" in features
            @test "rdep_b0.deprel=NOVAL" in features
        end
    end
end
