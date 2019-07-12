using Documenter, NDReducibles

makedocs(;
    modules=[NDReducibles],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        hide("internals.md"),
    ],
    repo="https://github.com/tkf/NDReducibles.jl/blob/{commit}{path}#L{line}",
    sitename="NDReducibles.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    strict = v"1.0" <= VERSION < v"1.2-",
)

deploydocs(;
    repo="github.com/tkf/NDReducibles.jl",
)
