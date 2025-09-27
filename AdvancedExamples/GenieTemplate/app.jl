using Pkg

cd(@__DIR__)
Pkg.activate(".")

using GenieTemplate

"serve" ∈ ARGS && wait(Condition())