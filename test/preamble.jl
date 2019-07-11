using Base.Broadcast: broadcasted, instantiate
using Test
using MacroTools
using NDReducibles
using NDReducibles: AccessPattern, Index, plan

_plan(pairs...) = plan(AccessPattern.(pairs)...)
_indices(idxs::String) = Index.(Tuple(Symbol.(collect(idxs))))

ND(n) = zeros(ntuple(_ -> 0, n))

macro test_inferred(ex)
    ex = quote
        $Test.@test (($Test.@inferred $ex); true)
    end
    esc(ex)
end

macro test_broken_inferred(ex)
    ex = quote
        $Test.@test_broken (($Test.@inferred $ex); true)
    end
    esc(ex)
end
