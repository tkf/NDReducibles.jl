#=
@inline foldlargs(op, x) = x
@inline foldlargs(op, x1, x2, xs...) = foldlargs(op, op(x1, x2), xs...)

@inline tuplediff(xs, ys) = foldlargs((), xs...) do zs, x
    Base.@_inline_meta
    foldlargs(false, ys...) do found, y
        Base.@_inline_meta
        found ? true : y == x
    end ? zs : (zs..., x)
end
=#

@inline tuplediff(xs, ys) = foldlargs((), xs...) do zs, x
    foldlargs(false, ys...) do _, y
        y == x && reduced(zs)
    end |> ifunreduced() do _
        (zs..., x)
    end
end

@inline tupleunion(xs, ys) = (xs..., tuplediff(ys, xs)...)
