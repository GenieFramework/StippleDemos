get!(ENV, "JULIA_CPU_TARGET", if strip(read(`uname -m`, String)) ∈ ["aarch64", "arm64"]
    "generic;cortex-a57;thunderx2t99;carmel"
else
    "generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
end)

@show ENV["JULIA_CPU_TARGET"]

using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.precompile()

# instantiate Python environment if needed
# using PythonCall
