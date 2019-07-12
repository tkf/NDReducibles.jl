module TestInference

include("preamble.jl")

f1() = _plan(
    ND(1) => (Index(:i),),
    ND(2) => (Index(:i), Index(:j)),
)

f2() = _plan(
    ND(1) => (:i,),
    ND(2) => (:i, :j),
)

@testset begin
    if VERSION < v"1.2-"
        @test_broken_inferred f1()
        @test_broken_inferred f2()
    else
        @test_inferred f1()
        @test_inferred f2()
    end
end

end  # module
