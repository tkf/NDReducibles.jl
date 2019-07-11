module TestReduce

include("preamble.jl")

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
    @test CAB.plan.indices == Index.((:j, :i))
    foreach(CAB) do (c, a, b)
        c[] += a * b
    end
    @test C == A * B
end

end  # module
