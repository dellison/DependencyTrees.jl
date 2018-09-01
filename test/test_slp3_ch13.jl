using DependencyTrees, Test

using DependencyTrees: ArcStandardConfig, leftarc, rightarc, shift, isfinal
using DependencyTrees: LeftArc, RightArc, Reduce, Shift
using DependencyTrees: training_oracle

@testset "ArcStandard" begin

    # figure 13.7 in jurafsky & martin SLP 3rd ed., aug 2018 draft
    sent = ["book", "me", "the", "morning", "flight"]

    word2id = Dict(word => id for (id, word) in enumerate(sent))
    word2id["root"] = 0

    words(ids) = [(id == 0 ? "root" : sent[id]) for id in ids]

    @testset "Untyped" begin

        # head --> dep
        hasdep(state, head, dep) = state.relations[word2id[dep]].head == word2id[head]

        gold_graph = DependencyGraph(UntypedDependency, [("book",0),("me",1),("my",5),("morning",5),("flight",1)])
        oracle = training_oracle(ArcStandardConfig, gold_graph)

        # step 0
        state = ArcStandardConfig{UntypedDependency}(sent)
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == ["book", "me", "the", "morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 1
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["me", "the", "morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 2
        @test words(state.stack) == ["root", "book", "me"]
        @test words(state.word_buffer) == ["the", "morning", "flight"]

        o = oracle(state)
        @test o == RightArc()
        @test o(state) == rightarc(state)
        state = rightarc(state)

        @test state.relations[word2id["me"]].head == word2id["book"]
        @test hasdep(state, "book", "me") # (book --> me)

        # step 3
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["the", "morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 4
        @test words(state.stack) == ["root", "book", "the"]
        @test words(state.word_buffer) == ["morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 5
        @test words(state.stack) == ["root", "book", "the", "morning"]
        @test words(state.word_buffer) == ["flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 6
        @test words(state.stack) == ["root", "book", "the", "morning", "flight"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == LeftArc()
        @test o(state) == leftarc(state)
        state = leftarc(state)

        @test hasdep(state, "flight", "morning") # (morning <-- flight)

        # step 7
        @test words(state.stack) == ["root", "book", "the", "flight"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == LeftArc()
        @test o(state) == leftarc(state)
        state = leftarc(state)

        @test hasdep(state, "flight", "the") # (the <-- flight)

        # step 8
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == RightArc()
        @test o(state) == rightarc(state)
        state = rightarc(state)

        @test hasdep(state, "book", "flight") # (book --> flight)

        # step 9
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == RightArc()
        @test o(state) == rightarc(state)
        state = o(state)

        @test hasdep(state, "root", "book") # (root --> book)

        # step 10
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == []
        @test isfinal(state)
    end

    @testset "Typed" begin

        gold_graph = DependencyGraph(TypedDependency, [("book","pred",0),("me","indobj",1),("my","dt",5),("morning","adv",5),("flight","dobj",1)])
        oracle = training_oracle(ArcStandardConfig, gold_graph)

        # head --> dep
        hasdeprel(state, head, deprel, dep) =
            state.relations[word2id[dep]].head == word2id[head] && state.relations[word2id[dep]].deprel == deprel

        # step 0
        state = ArcStandardConfig{TypedDependency}(sent)
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == ["book", "me", "the", "morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 1
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["me", "the", "morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 2
        @test words(state.stack) == ["root", "book", "me"]
        @test words(state.word_buffer) == ["the", "morning", "flight"]

        o = oracle(state)
        @test o == RightArc("indobj")
        @test o(state) == rightarc(state, "indobj")
        state = rightarc(state, "indobj")

        @test state.relations[word2id["me"]].head == word2id["book"]
        @test hasdeprel(state, "book", "indobj", "me") # (book -[indobj]-> me)

        # step 3
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["the", "morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 4
        @test words(state.stack) == ["root", "book", "the"]
        @test words(state.word_buffer) == ["morning", "flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 5
        @test words(state.stack) == ["root", "book", "the", "morning"]
        @test words(state.word_buffer) == ["flight"]

        o = oracle(state)
        @test o == Shift()
        @test o(state) == shift(state)
        state = shift(state)

        # step 6
        @test words(state.stack) == ["root", "book", "the", "morning", "flight"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == LeftArc("adv")
        @test o(state) == leftarc(state, "adv")
        state = leftarc(state, "adv")

        @test hasdeprel(state, "flight", "adv", "morning") # (morning <-[when?]- flight)

        # step 7
        @test words(state.stack) == ["root", "book", "the", "flight"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == LeftArc("dt")
        @test o(state) == leftarc(state, "dt")
        state = leftarc(state, "dt")

        @test hasdeprel(state, "flight", "dt", "the") # (the <-[the]- flight)

        # step 8
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == RightArc("dobj")
        @test o(state) == rightarc(state, "dobj")
        state = rightarc(state, "dobj")

        @test hasdeprel(state, "book", "dobj", "flight") # (book -[dobj]-> flight)

        # step 9
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == []

        o = oracle(state)
        @test o == RightArc("pred")
        @test o(state) == rightarc(state, "pred")
        state = rightarc(state, "pred")

        @test hasdeprel(state, "root", "pred", "book") # (root -[pred]-> book)

        # step 10
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == []
        @test isfinal(state)
    end
end

@testset "ArcEager" begin

    # figure 13.7 in jurafsky & martin SLP 3rd ed., aug 2018 draft
    sent = ["book", "the", "flight", "through", "houston"]

    word2id = Dict(word => id for (id, word) in enumerate(sent))
    word2id["root"] = 0

    words(ids) = [(id == 0 ? "root" : sent[id]) for id in ids]

    @testset "Untyped" begin

        using DependencyTrees: ArcEagerConfig, leftarc, rightarc, shift, reduce, isfinal

        # head --> dep
        hasdep(state, head, dep) = state.relations[word2id[dep]].head == word2id[head]

        # step 0
        state = ArcEagerConfig{UntypedDependency}(sent)
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == ["book", "the", "flight", "through", "houston"]
        state = rightarc(state)
        @test hasdep(state, "root", "book") # (root --> book)

        # step 1
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["the", "flight", "through", "houston"]
        state = shift(state)

        # step 2
        @test words(state.stack) == ["root", "book", "the"]
        @test words(state.word_buffer) == ["flight", "through", "houston"]
        state = leftarc(state)
        @test hasdep(state, "flight", "the") # (the <-- flight)

        # step 3
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["flight", "through", "houston"]
        state = rightarc(state)
        @test hasdep(state, "book", "flight") # (book --> flight)

        # step 4
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == ["through", "houston"]
        state = shift(state)

        # step 5
        @test words(state.stack) == ["root", "book", "flight", "through"]
        @test words(state.word_buffer) == ["houston"]
        state = leftarc(state)
        @test hasdep(state, "houston", "through") # (through <-- houston)

        # step 6
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == ["houston"]
        state = rightarc(state)
        @test hasdep(state, "flight", "houston") # (flight --> houston)

        # step 7
        @test words(state.stack) == ["root", "book", "flight", "houston"]
        @test words(state.word_buffer) == []
        state = reduce(state)

        # step 8
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == []
        state = reduce(state)

        # step 9
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == []
        state = reduce(state)
        @test hasdep(state, "root", "book") # (root --> book)

        # step 10
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == []
        @test isfinal(state)
    end

    @testset "Typed" begin

        using DependencyTrees: ArcEagerConfig, leftarc, rightarc, shift, reduce, isfinal

        # head --> dep
        hasdeprel(state, head, deprel, dep) =
            state.relations[word2id[dep]].head == word2id[head] && state.relations[word2id[dep]].deprel == deprel

        # step 0
        state = ArcEagerConfig{TypedDependency}(sent)
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == ["book", "the", "flight", "through", "houston"]

        state = rightarc(state, "pred")

        @test hasdeprel(state, "root", "pred", "book") # (root --> book)

        # step 1
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["the", "flight", "through", "houston"]

        state = shift(state)

        # step 2
        @test words(state.stack) == ["root", "book", "the"]
        @test words(state.word_buffer) == ["flight", "through", "houston"]

        state = leftarc(state, "det")

        @test hasdeprel(state, "flight", "det", "the") # (the <-- flight)

        # step 3
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == ["flight", "through", "houston"]

        state = rightarc(state, "dobj")

        @test hasdeprel(state, "book", "dobj", "flight") # (book --> flight)

        # step 4
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == ["through", "houston"]

        state = shift(state)

        # step 5
        @test words(state.stack) == ["root", "book", "flight", "through"]
        @test words(state.word_buffer) == ["houston"]

        state = leftarc(state, "pobj")

        @test hasdeprel(state, "houston", "pobj", "through") # (through <-- houston)

        # step 6
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == ["houston"]

        state = rightarc(state, "mod")

        @test hasdeprel(state, "flight", "mod", "houston") # (flight --> houston)

        # step 7
        @test words(state.stack) == ["root", "book", "flight", "houston"]
        @test words(state.word_buffer) == []

        state = reduce(state)

        # step 8
        @test words(state.stack) == ["root", "book", "flight"]
        @test words(state.word_buffer) == []

        state = reduce(state)

        # step 9
        @test words(state.stack) == ["root", "book"]
        @test words(state.word_buffer) == []

        state = reduce(state)

        # step 10
        @test words(state.stack) == ["root"]
        @test words(state.word_buffer) == []
        @test isfinal(state)
    end
end
