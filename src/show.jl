Base.show(io::IO, @nospecialize(_::Index{x})) where x =
    if get(io, :limit, false)
        print(io, '↻', x)
    else
        Base.show_default(io, Index(x))
    end

Base.show(io::IO, @nospecialize(plan::AccessPlan)) =
    if get(io, :limit, false)
        print(io, "AccessPlan: ")
        for (n, i) in enumerate(plan.indices)
            n == 1 || print(io, " → ")
            print(io, indexname(i))
        end
    else
        Base.show_default(io, plan)
    end

Base.show(io::IO, @nospecialize(reducible::NDReducible)) =
    if get(io, :limit, false)
        println(io, "NDReducible with ", length(reducible.patterns), " arrays")
        for pattern in reducible.patterns
            print(io, "* ")
            _summary(io, pattern.indexable)
            println(io)
            print(io, "  ")
            for (n, i) in enumerate(pattern.indices)
                n == 1 || print(io, " ")
                print(io, indexname(i))
            end
            println(io)
        end
        show(io, reducible.plan)
    else
        Base.show_default(io, reducible)
    end

_summary(io, x) = summary(io, x)
function _summary(io, x::Broadcasted)
    ax = axes(x)
    if length(ax) == 1
        print(io, length(ax[1]), "-element")
    else
        for (n, a) in enumerate(ax)
            n == 1 || print(io, "x")
            print(io, length(a))
        end
    end
    print(io, " Broadcasted")
end
