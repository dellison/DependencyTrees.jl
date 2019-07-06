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

    @testset "ArcEager" begin

        @test DependencyTrees.projective_only(ArcEager())

        # figure 13.8 in jurafsky & martin SLP 3rd ed., aug 2018 draft
        sent = ["book", "the", "flight", "through", "houston"]

        word2id = Dict(word => id for (id, word) in enumerate(sent))
        word2id["root"] = 0

        words(ids) = [(id == 0 ? "root" : sent[id]) for id in ids]

        @testset "Untyped" begin

            using DependencyTrees: ArcEager, leftarc, rightarc, shift, reduce, isfinal

            gold_graph = DependencyTree([UntypedDependency(i, t...)
                                          for (i, t) in enumerate([("book", 0),
                                                                   ("the", 3),
                                                                   ("flight", 1),
                                                                   ("through", 5),
                                                                   ("houston", 3)])])

            # head --> dep
            hasdep(state, head, dep) =
                token(state, word2id[dep]).head == word2id[head]

            # step 0
            state = DependencyTrees.initconfig(ArcEager(), UntypedDependency, sent)
            @test words(stack(state)) == ["root"]
            @test words(buffer(state)) == ["book", "the", "flight", "through", "houston"]
            state = rightarc(state)
            @test hasdep(state, "root", "book") # (root --> book)

            # step 1
            @test words(stack(state)) == ["root", "book"]
            @test words(buffer(state)) == ["the", "flight", "through", "houston"]
            state = shift(state)

            # step 2
            @test words(stack(state)) == ["root", "book", "the"]
            @test words(buffer(state)) == ["flight", "through", "houston"]
            state = leftarc(state)
            @test hasdep(state, "flight", "the") # (the <-- flight)

            # step 3
            @test words(stack(state)) == ["root", "book"]
            @test words(buffer(state)) == ["flight", "through", "houston"]
            state = rightarc(state)
            @test hasdep(state, "book", "flight") # (book --> flight)

            # step 4
            @test words(stack(state)) == ["root", "book", "flight"]
            @test words(buffer(state)) == ["through", "houston"]
            state = shift(state)

            # step 5
            @test words(stack(state)) == ["root", "book", "flight", "through"]
            @test words(buffer(state)) == ["houston"]
            state = leftarc(state)
            @test hasdep(state, "houston", "through") # (through <-- houston)

            # step 6
            @test words(stack(state)) == ["root", "book", "flight"]
            @test words(buffer(state)) == ["houston"]
            state = rightarc(state)
            @test hasdep(state, "flight", "houston") # (flight --> houston)

            # step 7
            @test words(stack(state)) == ["root", "book", "flight", "houston"]
            @test words(buffer(state)) == []
            state = reduce(state)

            # step 8
            @test words(stack(state)) == ["root", "book", "flight"]
            @test words(buffer(state)) == []
            state = reduce(state)

            # step 9
            @test words(stack(state)) == ["root", "book"]
            @test words(buffer(state)) == []
            state = reduce(state)
            @test hasdep(state, "root", "book") # (root --> book)

            # step 10
            @test words(stack(state)) == ["root"]
            @test words(buffer(state)) == []
            @test isfinal(state)

            # o = DependencyTrees.static_oracle(ArcEager(), gold_graph)

            pairs = DependencyTrees.xys(StaticOracle(ArcEager()), gold_graph)
            # @test last.(pairs) == [Shift(), Shift(), RightArc(), Shift(), Shift(), Shift(),
            #                        LeftArc(), LeftArc(), RightArc(), RightArc()]

            @test last.(pairs) == [RightArc(), Shift(), LeftArc(), RightArc(), Shift(),
                                   LeftArc(), RightArc()]#, Reduce(), Reduce(), Reduce()] 
            # throw an error if the parser makes a mistake
        end

        @testset "Typed" begin

            using DependencyTrees: ArcEager, leftarc, rightarc, shift, reduce, isfinal

            # head --> dep
            hasdeprel(state, head, deprel, dep) =
                token(state, word2id[dep]).head == word2id[head] && token(state, word2id[dep]).deprel == deprel

            gold_graph = DependencyTree([TypedDependency(i, t...)
                                          for (i, t) in enumerate([("book", "root", 0),
                                                                   ("the", "det", 3),
                                                                   ("flight", "dobj", 1),
                                                                   ("through", "case", 5),
                                                                   ("houston", "nmod", 3)])])
            
            # step 0
            state = initconfig(ArcEager(), TypedDependency, sent)
            @test words(stack(state)) == ["root"]
            @test words(buffer(state)) == ["book", "the", "flight", "through", "houston"]

            state = rightarc(state, "pred")

            @test hasdeprel(state, "root", "pred", "book") # (root --> book)

            # step 1
            @test words(stack(state)) == ["root", "book"]
            @test words(buffer(state)) == ["the", "flight", "through", "houston"]

            state = shift(state)

            # step 2
            @test words(stack(state)) == ["root", "book", "the"]
            @test words(buffer(state)) == ["flight", "through", "houston"]

            state = leftarc(state, "det")

            @test hasdeprel(state, "flight", "det", "the") # (the <-- flight)

            # step 3
            @test words(stack(state)) == ["root", "book"]
            @test words(buffer(state)) == ["flight", "through", "houston"]

            state = rightarc(state, "dobj")

            @test hasdeprel(state, "book", "dobj", "flight") # (book --> flight)

            # step 4
            @test words(stack(state)) == ["root", "book", "flight"]
            @test words(buffer(state)) == ["through", "houston"]

            state = shift(state)

            # step 5
            @test words(stack(state)) == ["root", "book", "flight", "through"]
            @test words(buffer(state)) == ["houston"]

            state = leftarc(state, "pobj")

            @test hasdeprel(state, "houston", "pobj", "through") # (through <-- houston)

            # step 6
            @test words(stack(state)) == ["root", "book", "flight"]
            @test words(buffer(state)) == ["houston"]

            state = rightarc(state, "mod")

            @test hasdeprel(state, "flight", "mod", "houston") # (flight --> houston)

            # step 7
            @test words(stack(state)) == ["root", "book", "flight", "houston"]
            @test words(buffer(state)) == []

            state = reduce(state)

            # step 8
            @test words(stack(state)) == ["root", "book", "flight"]
            @test words(buffer(state)) == []

            state = reduce(state)

            # step 9
            @test words(stack(state)) == ["root", "book"]
            @test words(buffer(state)) == []

            state = reduce(state)

            # step 10
            @test words(stack(state)) == ["root"]
            @test words(buffer(state)) == []
            @test isfinal(state)
       end
    end
end
