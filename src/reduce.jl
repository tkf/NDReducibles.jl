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
        acc = @next(rf, acc, tryaccess(patterns, indexmap, accessed))
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
