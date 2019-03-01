struct OnlineTrainer{O<:Oracle,M,F,U}
    oracle::O
    model::M
    featurize::F
    update_function::U
end

function train!(trainer::OnlineTrainer{<:StaticOracle}, graph::DependencyTree)
    f = trainer.featurize
    update = trainer.update_function
    model = trainer.model
    for (config, gold_t) in StaticGoldPairs(trainer.oracle, graph)
        features = f(config)
        prediction = model(features)
        if prediction != gold_t
            update(features, prediction, gold_t)
        end
    end
end

function train!(trainer::OnlineTrainer{<:StaticOracle}, graphs::Treebank;
                epochs=1)
    data = xys(trainer.oracle, graphs)
    xs, ys = trainer.featurize.(first.(data)), last.(data)
    for epoch = 1:epochs
        for (x, y) in zip(xs, ys)
            ŷ = trainer.model(x)
            if ŷ != y
                trainer.update_function(x, ŷ, y)
            end
        end
    end
end

function train!(trainer::OnlineTrainer{<:DynamicOracle}, graph::DependencyTree;
                choose_next = choose_next_amb)
    fx, update, model = trainer.featurize, trainer.update_function, trainer.model
    cfg = initconfig(trainer.oracle.transition_system, graph)
    while !isfinal(cfg)
        features = fx(cfg)
        pred = model(features)
        gold = gold_transitions(trainer.oracle, cfg, graph)
        t = choose_next(pred, gold)
        if !(pred in gold)
            update(features, pred, t)
        end
        cfg = t(cfg)
    end
end

function train!(trainer::OnlineTrainer{<:DynamicOracle}, graphs::Treebank,
                choose_next = choose_next_amb)
    for graph in graphs
        train!(trainer, graph, choose_next = choose_next)
    end
end
