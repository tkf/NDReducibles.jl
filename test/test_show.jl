module TestShow

include("preamble.jl")

function nullshows(x)
    io = devnull
    # io = stdout
    show(io, x)
    show(IOContext(io, :limit => true), x)
    show(io, "text/plain", x)
    show(IOContext(io, :limit => true), "text/plain", x)
    return true
end

@testset begin
    n = 3
    C = zeros(n)
    A = rand(-10:10, n, n)
    B = rand(-10:10, n)
    CAB = ndreducible(
        instantiate(broadcasted(Ref, Ref(C), eachindex(C))) => (:i,),
        A => (:i, :j),
        B => (:j,),
    )
    @test nullshows(CAB.plan.indices[1])
    @test nullshows(CAB.plan)
    @test nullshows(CAB)
    @test nullshows(CAB.patterns)
    @test nullshows(CAB.patterns[1])
end

end  # module
