# tests from chapter 13 of the draft of "Speech and Language
# Processing" 3rd edition by Jurafsky & Martin

@testset "J&M 3ed Ch 13" begin

    sent_f13_7 = ["book", "me", "the", "morning", "flight"]

    # leftovers:
    sent = sent_f13_7

    word2id = Dict(word => id for (id, word) in enumerate(sent))
    word2id["root"] = 0

    words(ids) = [(id == 0 ? "root" : sent[id]) for id in ids]

    @testset "Figure 13.7" begin
        @test projective_only(ArcStandard())

        # figure 13.7 in jurafsky & martin SLP 3rd ed., aug 2018 draft
        table = [
            # stack                                    buffer                                  # transition
            (["ROOT"],                                 ["book","me","the","morning","flight"], Shift()),
            (["ROOT","book"],                          ["me","the","morning","flight"],        Shift()),
            (["ROOT","book","me"],                     ["the","morning","flight"],             RightArc("indobj")),
            (["ROOT","book"],                          ["the","morning","flight"],             Shift()),
            (["ROOT","book","the"],                    ["morning","flight"],                   Shift()),
            (["ROOT","book","the","morning"],          ["flight"],                             Shift()),
            (["ROOT","book","the","morning","flight"], [],                                     LeftArc("adv")),
            (["ROOT","book","the","flight"],           [],                                     LeftArc("dt")),
            (["ROOT","book","flight"],                 [],                                     RightArc("dobj")),
            (["ROOT","book",],                         [],                                     RightArc("pred")),
            (["ROOT",],                                [],                                     nothing)]
        sent = copy(sent_f13_7)

        gold_tree = test_sentence("morningflight.conll")

        for arc in (untyped, typed)
            o = cfg -> static_oracle(cfg, gold_tree, arc)
            cfg = initconfig(ArcStandard(), gold_tree)
            for (stk, buf, t) in table
                @test form.(tokens(cfg, stack(cfg))) == stk
                @test form.(tokens(cfg, buffer(cfg))) == buf
                t == nothing && break
                if arc == untyped
                    t isa LeftArc && (t = LeftArc())
                    t isa RightArc && (t = RightArc())
                end
                @test o(cfg) == t
                cfg = t(cfg)
            end
        end
    end

    @testset "Figure 13.8" begin
        @test projective_only(ArcStandard())

        # figure 13.8 in jurafsky & martin SLP 3rd ed., aug 2018 draft
        table = [
            # stack                                    buffer                                  # transition
            (["ROOT"],                                 ["book","the","flight","through","houston"], Shift()),
            (["ROOT","book"],                          ["the","flight","through","houston"],   Shift()),
            (["ROOT","book","the"],                    ["flight","through","houston"],         Shift()),
            (["ROOT","book","the","flight"],           ["through","houston"],                  LeftArc("det")),
            (["ROOT","book","flight"],                 ["through","houston"],                  Shift()),
            (["ROOT","book","flight","through"],       ["houston"],                            Shift()),
            (["ROOT","book","flight","through","houston"], [],                                 LeftArc("case")),
            (["ROOT","book","flight","houston"],       [],                                     RightArc("nmod")),
            (["ROOT","book","flight"],                 [],                                     RightArc("dobj")),
            (["ROOT","book",],                         [],                                     RightArc("root")),
            (["ROOT",],                                [],                                     nothing)]
        sent = copy(sent_f13_7)

        gold_tree = test_sentence("flightthroughhouston.conll")

        for arc in (untyped, typed)
            o = cfg -> static_oracle(cfg, gold_tree, arc)
            cfg = initconfig(ArcStandard(), gold_tree)
            for (stk, buf, t) in table
                @test form.(tokens(cfg, stack(cfg))) == stk
                @test form.(tokens(cfg, buffer(cfg))) == buf
                t == nothing && break
                if arc == untyped
                    t isa LeftArc && (t = LeftArc())
                    t isa RightArc && (t = RightArc())
                    @test endswith(showstr(t), "()")
                end
                @test o(cfg) == t
                cfg = t(cfg)
            end
        end
    end

    @testset "Figure 13.10" begin

        @test DependencyTrees.projective_only(ArcEager())

        table = [
            # stack                                    buffer                                  # transition
            (["ROOT"],                                 ["book","the","flight","through","houston"], RightArc("root")),
            (["ROOT","book"],                          ["the","flight","through","houston"],   Shift()),
            (["ROOT","book","the"],                    ["flight","through","houston"],         LeftArc("det")),
            (["ROOT","book"],                          ["flight","through","houston"],         RightArc("dobj")),
            (["ROOT","book","flight"],                 ["through","houston"],                  Shift()),
            (["ROOT","book","flight","through"],       ["houston"],                            LeftArc("case")),
            (["ROOT","book","flight"] ,                ["houston"],                            RightArc("nmod")),
            (["ROOT","book","flight","houston"],       [],                                     Reduce()),
            (["ROOT","book","flight"],                 [],                                     Reduce()),
            (["ROOT","book"],                          [],                                     Reduce()),
            (["ROOT"],                                 [],                                     nothing)]

        gold_tree = test_sentence("flightthroughhouston.conll")

        for arc in (untyped, typed)
            o = cfg -> static_oracle(cfg, gold_tree, arc)
            cfg = initconfig(ArcEager(), gold_tree)
            for (stk, buf, t) in table
                @test form.(tokens(cfg, stack(cfg))) == stk
                @test form.(tokens(cfg, buffer(cfg))) == buf
                t == nothing && break
                if arc == untyped
                    t isa LeftArc && (t = LeftArc())
                    t isa RightArc && (t = RightArc())
                    @test endswith(showstr(t), "()")
                end
                @test o(cfg) == t
                if o(cfg) != t
                    @show stk buf t cfg o(cfg)
                end
                cfg = t(cfg)
            end
            @test isfinal(cfg)
        end
    end
end
