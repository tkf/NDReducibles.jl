"""
    ndreducible(A => (:i, :j, ...), B => (...), ..., C => (...))

Given pairs of an array (or a `Broadcasted`) and indices,
`ndreducible` "couples" the arrays with shared index and plan the best
nested `for`-loop along all the indices.  `ndreducible` returns a
fold-able object which can be used with `foldl` and `foreach` defined
in Transducers.jl.  Use `referenceable` from Referenceables.jl to
mutate arrays.

See also: [`plan`](@ref).

# Examples

```math
C_{ij} = ∑_k A_{ik} B_{kj} + C_{ij}
```

```jldoctest
julia> using NDReducibles
       using Referenceables: referenceable

julia> A = rand(-10:10, 5, 4)
       B = rand(-10:10, 4, 3)
       C = zeros(Int, 5, 3);

julia> foreach(
           ndreducible(
               referenceable(C) => (:i, :j),
               A => (:i, :k),
               B => (:k, :j),
           ),
           simd = :ivdep,  # optional
       ) do (c, a, b)
           c[] += a * b
       end;

julia> C == A * B
true
```

```math
∑_i A_i B_i C_i
```

```jldoctest
julia> using NDReducibles
       using Transducers: MapSplat

julia> A = rand(-10:10, 5)
       B = rand(-10:10, 5)
       C = rand(-10:10, 5);

julia> foldl(
           +,
           MapSplat(*),
           ndreducible(
               A => (:i,),
               B => (:i,),
               C => (:i,),
           ),
           simd = true,  # optional
       ) == sum(A .* B .* C)
true
```

```math
∑ \\{ A_i B_i C_i \\;|\\; A_i > 0 \\}
```

```jldoctest
julia> using NDReducibles
       using Transducers: MapSplat, Filter

julia> A = rand(-10:10, 5)
       B = rand(-10:10, 5)
       C = rand(-10:10, 5);

julia> foldl(
           +,
           Filter(((a, b, c),) -> a > 0) |> MapSplat(*),
           ndreducible(
               A => (:i,),
               B => (:i,),
               C => (:i,),
           ),
           simd = true,  # optional
       ) == sum(A .* (A .> 0) .* B .* C)
true
```
"""
function ndreducible(pairs...)
    patterns = map(AccessPattern, pairs)
    # TODO: check consistency of patterns
    return NDReducible(patterns, plan(patterns...))
end

struct NDReducible{T <: NTuple{<:Any, AccessPattern}, P} <: Foldable
    # TODO: NDReducible <: Reducible
    patterns::T
    plan::P
end

struct NAY end  # not accessed yet

function Transducers.__foldl__(rf, acc, coll::NDReducible)
    accessed = ntuple(_ -> NAY(), length(coll.patterns))
    result = _ndreduce(rf, acc, accessed, (), coll.patterns, coll.plan.indices...)
    @return_if_reduced result
    return complete(rf, result)
end

@inline function _ndreduce(rf, acc, accessed, indexmap0, patterns, i, indices...)
    for j in axisfor(patterns, i)
        indexmap = (indexmap0..., i => j)
        acc = @return_if_reduced _ndreduce(
            rf,
            acc,
            tryaccess(patterns, indexmap, accessed),
            indexmap,
            patterns,
            indices...,
        )
    end
    return acc
end

@inline function _ndreduce(rf, acc, accessed, indexmap0, patterns, i)
    @simd_if rf for j in axisfor(patterns, i)
        indexmap = (indexmap0..., i => j)
        @next!(rf, acc, tryaccess(patterns, indexmap, accessed))
    end
    return acc
end

axisfor(patterns, i) =
    foldlargs(nothing, patterns...) do _, p::AccessPattern
        foldlargs(nothing, ntuple(identity, length(p.indices))...) do _, n
            if p.indices[n] === i
                reduced(axes(p.indexable)[n])
            else
                nothing
            end
        end
    end |> unreduced

@inline tryaccess(patterns, indexmap, accessed) =
    map(patterns, accessed) do (p::AccessPattern), value
        value isa NAY || return value
        idxvalue = map(p.indices) do (i::Index)
            foldlargs(NAY(), indexmap...) do found, (iname, ivalue)
                found isa NAY || return found
                (iname::Index) === i ? (ivalue::Int) : NAY()
            end
        end
        if idxvalue isa Tuple{Vararg{Int}}
            @inbounds p.indexable[idxvalue...]
        else
            NAY()
        end
    end
