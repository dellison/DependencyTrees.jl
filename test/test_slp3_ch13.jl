using DependencyTrees, Test

using DependencyTrees: ArcStandard, leftarc, rightarc, shift, isfinal
using DependencyTrees: LeftArc, RightArc, Reduce, Shift
using DependencyTrees: static_oracle, DeterministicParserTrainer

# tests from chapter 13 of the draft of "Speech and Language
# Processing" 3rd edition by Jurafsky & Martin

@testset "J&M 3ed Ch 13" begin

    @testset "ArcStandard" begin

        # figure 13.7 in jurafsky & martin SLP 3rd ed., aug 2018 draft
        sent = ["book", "me", "the", "morning", "flight"]

        word2id = Dict(word => id for (id, word) in enumerate(sent))
        word2id["root"] = 0

        words(ids) = [(id == 0 ? "root" : sent[id]) for id in ids]

        @testset "Untyped" begin

            # head --> dep
            hasdep(state, head, dep) = state.A[word2id[dep]].head == word2id[head]

            gold_graph = DependencyGraph(UntypedDependency, [("book",0),
                                                             ("me",1),
                                                             ("the",5),
                                                             ("morning",5),
                                                             ("flight",1)])
            oracle = static_oracle(ArcStandard, gold_graph)

            # step 0
            state = ArcStandard{UntypedDependency}(sent)
            @test words(state.σ) == ["root"]
            @test words(state.β) == ["book", "me", "the", "morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 1
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["me", "the", "morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 2
            @test words(state.σ) == ["root", "book", "me"]
            @test words(state.β) == ["the", "morning", "flight"]

            o = oracle(state)
            @test o == RightArc()
            @test o(state) == rightarc(state)
            state = rightarc(state)

            @test state.A[word2id["me"]].head == word2id["book"]
            @test hasdep(state, "book", "me") # (book --> me)

            # step 3
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["the", "morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 4
            @test words(state.σ) == ["root", "book", "the"]
            @test words(state.β) == ["morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 5
            @test words(state.σ) == ["root", "book", "the", "morning"]
            @test words(state.β) == ["flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 6
            @test words(state.σ) == ["root", "book", "the", "morning", "flight"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == LeftArc()
            @test o(state) == leftarc(state)
            state = leftarc(state)

            @test hasdep(state, "flight", "morning") # (morning <-- flight)

            # step 7
            @test words(state.σ) == ["root", "book", "the", "flight"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == LeftArc()
            @test o(state) == leftarc(state)
            state = leftarc(state)

            @test hasdep(state, "flight", "the") # (the <-- flight)

            # step 8
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == RightArc()
            @test o(state) == rightarc(state)
            state = rightarc(state)

            @test hasdep(state, "book", "flight") # (book --> flight)

            # step 9
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == RightArc()
            @test o(state) == rightarc(state)
            state = o(state)

            @test hasdep(state, "root", "book") # (root --> book)

            # step 10
            @test words(state.σ) == ["root"]
            @test words(state.β) == []
            @test isfinal(state)

            graph = DependencyTrees.parse(ArcStandard{UntypedDependency}, sent, oracle)
            @test graph == gold_graph

            trainer = DeterministicParserTrainer(ArcStandard{TypedDependency}, identity)
            pairs = DependencyTrees.training_pairs(trainer, graph)
            @test last.(pairs) == [Shift(), Shift(), RightArc(), Shift(), Shift(), Shift(),
                                   LeftArc(), LeftArc(), RightArc(), RightArc()]
        end

        @testset "Typed" begin

            gold_graph = DependencyGraph(TypedDependency, [("book","pred",0),("me","indobj",1),("the","dt",5),("morning","adv",5),("flight","dobj",1)])
            oracle = static_oracle(ArcStandard, gold_graph)

            # head --> dep
            hasdeprel(state, head, deprel, dep) =
                state.A[word2id[dep]].head == word2id[head] && state.A[word2id[dep]].deprel == deprel

            # step 0
            state = ArcStandard{TypedDependency}(sent)
            @test words(state.σ) == ["root"]
            @test words(state.β) == ["book", "me", "the", "morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 1
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["me", "the", "morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 2
            @test words(state.σ) == ["root", "book", "me"]
            @test words(state.β) == ["the", "morning", "flight"]

            o = oracle(state)
            @test o == RightArc("indobj")
            @test o(state) == rightarc(state, "indobj")
            state = rightarc(state, "indobj")

            @test state.A[word2id["me"]].head == word2id["book"]
            @test hasdeprel(state, "book", "indobj", "me") # (book -[indobj]-> me)

            # step 3
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["the", "morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 4
            @test words(state.σ) == ["root", "book", "the"]
            @test words(state.β) == ["morning", "flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 5
            @test words(state.σ) == ["root", "book", "the", "morning"]
            @test words(state.β) == ["flight"]

            o = oracle(state)
            @test o == Shift()
            @test o(state) == shift(state)
            state = shift(state)

            # step 6
            @test words(state.σ) == ["root", "book", "the", "morning", "flight"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == LeftArc("adv")
            @test o(state) == leftarc(state, "adv")
            state = leftarc(state, "adv")

            @test hasdeprel(state, "flight", "adv", "morning") # (morning <-[when?]- flight)

            # step 7
            @test words(state.σ) == ["root", "book", "the", "flight"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == LeftArc("dt")
            @test o(state) == leftarc(state, "dt")
            state = leftarc(state, "dt")

            @test hasdeprel(state, "flight", "dt", "the") # (the <-[the]- flight)

            # step 8
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == RightArc("dobj")
            @test o(state) == rightarc(state, "dobj")
            state = rightarc(state, "dobj")

            @test hasdeprel(state, "book", "dobj", "flight") # (book -[dobj]-> flight)

            # step 9
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == []

            o = oracle(state)
            @test o == RightArc("pred")
            @test o(state) == rightarc(state, "pred")
            state = rightarc(state, "pred")

            @test hasdeprel(state, "root", "pred", "book") # (root -[pred]-> book)

            # step 10
            @test words(state.σ) == ["root"]
            @test words(state.β) == []
            @test isfinal(state)

            graph = DependencyTrees.parse(ArcStandard{TypedDependency}, sent, oracle)
            @test graph == gold_graph

            trainer = DeterministicParserTrainer(ArcStandard{TypedDependency}, identity)
            pairs = DependencyTrees.training_pairs(trainer, graph)
            @test last.(pairs) == [Shift(), Shift(), RightArc("indobj"), Shift(), Shift(), Shift(), LeftArc("adv"), LeftArc("dt"), RightArc("dobj"), RightArc("pred")]
        end
    end

    @testset "ArcEager" begin

        # figure 13.8 in jurafsky & martin SLP 3rd ed., aug 2018 draft
        sent = ["book", "the", "flight", "through", "houston"]

        word2id = Dict(word => id for (id, word) in enumerate(sent))
        word2id["root"] = 0

        words(ids) = [(id == 0 ? "root" : sent[id]) for id in ids]

        @testset "Untyped" begin

            using DependencyTrees: ArcEager, leftarc, rightarc, shift, reduce, isfinal

            gold_graph = DependencyGraph([UntypedDependency(i, t...)
                                          for (i, t) in enumerate([("book", 0),
                                                                   ("the", 3),
                                                                   ("flight", 1),
                                                                   ("through", 5),
                                                                   ("houston", 3)])])

            # head --> dep
            hasdep(state, head, dep) = state.A[word2id[dep]].head == word2id[head]

            # step 0
            state = ArcEager{UntypedDependency}(sent)
            @test words(state.σ) == ["root"]
            @test words(state.β) == ["book", "the", "flight", "through", "houston"]
            state = rightarc(state)
            @test hasdep(state, "root", "book") # (root --> book)

            # step 1
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["the", "flight", "through", "houston"]
            state = shift(state)

            # step 2
            @test words(state.σ) == ["root", "book", "the"]
            @test words(state.β) == ["flight", "through", "houston"]
            state = leftarc(state)
            @test hasdep(state, "flight", "the") # (the <-- flight)

            # step 3
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["flight", "through", "houston"]
            state = rightarc(state)
            @test hasdep(state, "book", "flight") # (book --> flight)

            # step 4
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == ["through", "houston"]
            state = shift(state)

            # step 5
            @test words(state.σ) == ["root", "book", "flight", "through"]
            @test words(state.β) == ["houston"]
            state = leftarc(state)
            @test hasdep(state, "houston", "through") # (through <-- houston)

            # step 6
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == ["houston"]
            state = rightarc(state)
            @test hasdep(state, "flight", "houston") # (flight --> houston)

            # step 7
            @test words(state.σ) == ["root", "book", "flight", "houston"]
            @test words(state.β) == []
            state = reduce(state)

            # step 8
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == []
            state = reduce(state)

            # step 9
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == []
            state = reduce(state)
            @test hasdep(state, "root", "book") # (root --> book)

            # step 10
            @test words(state.σ) == ["root"]
            @test words(state.β) == []
            @test isfinal(state)

            oracle = DependencyTrees.static_oracle(ArcEager, gold_graph)
            graph = DependencyTrees.parse(ArcEager{UntypedDependency}, sent, oracle)
            @test graph == gold_graph

            trainer = DeterministicParserTrainer(ArcEager{UntypedDependency}, identity)
            pairs = DependencyTrees.training_pairs(trainer, graph)
            @test last.(pairs) == [RightArc(), Shift(), LeftArc(), RightArc(), Shift(),
                                   LeftArc(), RightArc()]#, Reduce(), Reduce(), Reduce()]
        end

        @testset "Typed" begin

            using DependencyTrees: ArcEager, leftarc, rightarc, shift, reduce, isfinal

            # head --> dep
            hasdeprel(state, head, deprel, dep) =
                state.A[word2id[dep]].head == word2id[head] && state.A[word2id[dep]].deprel == deprel

            gold_graph = DependencyGraph([TypedDependency(i, t...)
                                          for (i, t) in enumerate([("book", "root", 0),
                                                                   ("the", "det", 3),
                                                                   ("flight", "dobj", 1),
                                                                   ("through", "case", 5),
                                                                   ("houston", "nmod", 3)])])
            
            # step 0
            state = ArcEager{TypedDependency}(sent)
            @test words(state.σ) == ["root"]
            @test words(state.β) == ["book", "the", "flight", "through", "houston"]

            state = rightarc(state, "pred")

            @test hasdeprel(state, "root", "pred", "book") # (root --> book)

            # step 1
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["the", "flight", "through", "houston"]

            state = shift(state)

            # step 2
            @test words(state.σ) == ["root", "book", "the"]
            @test words(state.β) == ["flight", "through", "houston"]

            state = leftarc(state, "det")

            @test hasdeprel(state, "flight", "det", "the") # (the <-- flight)

            # step 3
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == ["flight", "through", "houston"]

            state = rightarc(state, "dobj")

            @test hasdeprel(state, "book", "dobj", "flight") # (book --> flight)

            # step 4
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == ["through", "houston"]

            state = shift(state)

            # step 5
            @test words(state.σ) == ["root", "book", "flight", "through"]
            @test words(state.β) == ["houston"]

            state = leftarc(state, "pobj")

            @test hasdeprel(state, "houston", "pobj", "through") # (through <-- houston)

            # step 6
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == ["houston"]

            state = rightarc(state, "mod")

            @test hasdeprel(state, "flight", "mod", "houston") # (flight --> houston)

            # step 7
            @test words(state.σ) == ["root", "book", "flight", "houston"]
            @test words(state.β) == []

            state = reduce(state)

            # step 8
            @test words(state.σ) == ["root", "book", "flight"]
            @test words(state.β) == []

            state = reduce(state)

            # step 9
            @test words(state.σ) == ["root", "book"]
            @test words(state.β) == []

            state = reduce(state)

            # step 10
            @test words(state.σ) == ["root"]
            @test words(state.β) == []
            @test isfinal(state)

            oracle = DependencyTrees.static_oracle(ArcEager, gold_graph)
            graph = DependencyTrees.parse(ArcEager{TypedDependency}, sent, oracle)
            @test graph == gold_graph

            trainer = DeterministicParserTrainer(ArcEager{TypedDependency}, identity)
            pairs = DependencyTrees.training_pairs(trainer, graph)
            @test last.(pairs) == [RightArc("root"), Shift(), LeftArc("det"), RightArc("dobj"), Shift(),
                                   LeftArc("case"), RightArc("nmod")
                                   ]#, Reduce(), Reduce(), Reduce()]
       end
    end
end
