# TODO keep track of outgoing arcs?
"""
    DependencyTree

A rooted tree of dependency relations among the tokens of a sentence.
"""
struct DependencyTree{T<:Token, R<:Union{Int,Set{Int}}}
    tokens::Vector{T}
    root::R
end

"""
    deptree(read_token, xs)

Create a `DependencyTree` by calling `read_token` on each of `xs`.
"""
function deptree end

function deptree(tokens)
    return DependencyTree(tokens, find_root(tokens))
end

function deptree(read_token, xs)
    tokens = Token[]
    for x in xs
        try
            token = read_token(x)
            push!(tokens, token)
        catch err
            if err isa EmptyTokenError
                continue
            elseif err isa MultiWordTokenError
                continue
            else
                throw(err)
            end
        end
    end
    tokens = identity.(tokens) # type info
    root = find_root(tokens)
    return DependencyTree(tokens, root)
end

function deptree(lines::String, read_token=from_conllu)
    lines = [line for line in split(strip(lines), "\n")]
    lines = filter(x -> !startswith(x, "#"), lines)
    return deptree(read_token, lines)
end

function find_root(tokens)
    root = [i for (i, token) in enumerate(tokens) if has_head(token, 0)]
    return length(root) == 1 ? root[1] : Set(root)
end

"""
    arcs(tree::DependencyTree)

Return a vector of (src, dst) tuples, representing all dependency arcs in `tree`.
"""
arcs(tree::DependencyTree) =
    [(h, d) for (d, tok) in enumerate(tree.tokens) for h in tok.head]

deps(tree::DependencyTree, i::Int) =
    filter(j -> has_head(tree.tokens[j], i), 1:length(tree))

leftdeps(tree::DependencyTree, i::Int) = filter(j -> j < i, deps(tree, i))

function leftmostdep(tree::DependencyTree, i::Int)
    ds = leftdeps(tree, i)
    isempty(ds) ? -1 : first(ds)
end

rightdeps(tree::DependencyTree, i::Int) = filter(j -> j > i, deps(tree, i))

function rightmostdep(tree::DependencyTree, i::Int)
    ds = rightdeps(tree, i)
    isempty(ds) ? -1 : last(ds)
end

has_arc(tree::DependencyTree, head::Int, dependant::Int) =
    iszero(dependant) ? false : has_head(tree.tokens[dependant], head)

children(tree::DependencyTree; recursive=false) =
    [children(tree, i; recursive=recursive) for i in 1:length(tree)]

function children(tree::DependencyTree, i::Int; recursive=false)
    ch = [c for (c, tok) in enumerate(tree.tokens) if has_head(tok, i)]
    if recursive
        for c in ch
            append!(ch, children(tree, c))
        end
    end
    return ch
end

token(tree::DependencyTree, i) =
    iszero(i) ? ROOT : tree.tokens[i]

function is_projective(tree::DependencyTree)
    # For every arc (i,l,j) there is a directed path from i to every
    # word k such that min(i,j) < k < max(i,j)
    arc = (a, b) -> has_arc(tree, a, b)
    for (parent, child) in arcs(tree)
        child > parent && ((child, parent) = (parent, child))
        for k in child+1:parent-1
            for m in 1:length(tree)#Iterators.flatten((1:i-1, j+1:length(tree)))
                if m < child || m > parent
                    if arc(k, m) || arc(m, k)
                        return false
                    end
                end
            end
        end
    end
    return true
end
    
struct ArrowCharset
    arrow::Char
    ur::Char # up/right
    ud::Char # up/down
    lr::Char # left/right
    dr::Char # down/right
end
DEFAULT_ARROWS = ArrowCharset('►','└','│','─','┌') 
ASCII_ARROWS   = ArrowCharset('>', '\'', '|', '-', ',')

function prettyprint(tree::DependencyTree; charset=DEFAULT_ARROWS)
    n = length(tree)
    lines = ["" for _=1:n+1]
    queue = sort(arcs(tree), by = (arc) -> abs(-(arc...)))
    for (h, d) in queue
        iszero(h) && continue # leave root arc until the end
        lines = drawarrow!(lines, h+1, d+1, charset)
    end
    for root in tree.root
        lines = drawarrow!(lines, 1, root+1, charset)
    end
    max_height = maximum(length.(lines))
    lines = map(enumerate(lines)) do (i, line)
        height = length(line)
        leftpad = repeat(" ", max_height - height)
        leftpad * line * " " * tree[i-1].form
    end
    return join(lines, "\n")
end

function drawarrow!(lines, from, to, cs)
    middle = cs.ud * "  "
    if from < to # pointing "down" the sentence
        range = from:to
        base = cs.dr * cs.lr * cs.lr
        head = cs.ur * cs.lr * cs.arrow
        arrow = [base; [middle for i in from+1:to-1]; head]
    else
        range = to:from
        arrow = [cs.dr * cs.lr * cs.arrow;
                 [middle for i in to+1:from-1];
                 cs.ur * cs.lr * cs.lr]
    end
    heights = length.(lines[i] for i in range)
    max_height = maximum(heights)
    for (i, (r, h, a)) in enumerate(zip(range, heights, arrow))
        if r == from
            lines[r] = a * repeat(cs.lr, max_height - h) * lines[r]
        elseif r == to
            # redraw the arrowhead to go all the way down
            arr = a[1][1] * repeat(cs.lr, max(0, max_height - h) + 1) * cs.arrow
            lines[r] = arr * lines[r]
        else
            lines[r] = a * repeat(" ", max_height - h) * lines[r]
        end
    end
    return lines
end

Base.getindex(tree::DependencyTree, i::Int) = iszero(i) ? ROOT : tree.tokens[i]

Base.iterate(tree::DependencyTree, state...) = iterate(tree.tokens, state...)

Base.length(tree::DependencyTree) = length(tree.tokens)

Base.show(io::IO, tree::DependencyTree) =
    print(io, prettyprint(tree))
    
==(a::DependencyTree, b::DependencyTree) = all(a.tokens .== b.tokens)
