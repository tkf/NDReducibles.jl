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
    # @test_inferred f1()  # running this twice in REPL makes it pass...
    @test_broken_inferred f2()
end

end  # module
