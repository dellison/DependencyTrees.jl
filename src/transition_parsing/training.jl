abstract type TransitionParserTrainer end

struct DeterministicParserTrainer <: TransitionParserTrainer
    C::Type{<:TransitionParserConfiguration}
    featurize::Function
end

# generate training data for deterministic dependency parsing
# i.e. go from parsed trees to (config, gold_transition) pairs
function training_pairs(t::DeterministicParserTrainer, gold_tree)
    oracle = static_oracle(t.C, gold_tree)
    pairs = []
    cfg = t.C(form.(gold_tree))
    while !isfinal(cfg)
        x = t.featurize(cfg)
        y = oracle(cfg)
        push!(pairs, (x, y))
        cfg = y(cfg)
    end
    return pairs
end
