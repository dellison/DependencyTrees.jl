abstract type TransitionParserTrainer end

struct DeterministicParserTrainer <: TransitionParserTrainer
    C::Type{<:TransitionParserConfiguration}
    featurize::Function
end

# generate training data for deterministic greedy dependency parsing
# i.e. go from parsed trees to vector of (config, gold_transition) pairs
function training_pairs(t::DeterministicParserTrainer, gold_tree, oracle=static_oracle)
    o = oracle(t.C, gold_tree)
    pairs = []
    cfg = t.C(form.(gold_tree))
    while !isfinal(cfg)
        x = t.featurize(cfg)
        y = o(cfg)
        push!(pairs, (x, y))
        cfg = y(cfg)
    end
    return pairs
end

function train_online(t::DeterministicParserTrainer, corpus, n_iter, predict, update, oracle=static_oracle)
    for i in 1:n_iter, gold_tree in corpus
        o = oracle(t.C, gold_tree)
        cfg = t.C(form.(gold_tree))
        while !isfinal(cfg)
            tp = predict(cfg)
            to = o(cfg)
            tp == to || update()
            cfg = to(cfg)
        end
    end
end

