cd(@__DIR__)
push!(LOAD_PATH, @__DIR__)

using Pkg
pkg"activate ."

if isempty(ARGS)
  error(
    "
    Please pass the file you want to run.
    Ex: julia run.jl StippleButtons.jl
    ")
end

filename = basename(ARGS[1])

if !in(filename, readdir(@__DIR__)) || !isfile(filename)
  error("$filename is not a proper Julia script")
end

using Revise
Revise.includet(filename)

up(rand((8000:9000)), open_browser=true)

while true
  sleep(1_000_000)
end