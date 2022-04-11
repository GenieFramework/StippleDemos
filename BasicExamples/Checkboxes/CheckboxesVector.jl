using Stipple, StippleUI
using OffsetArrays

@reactive! mutable struct Model <: ReactiveModel
    valone::R{Bool} = false
    valtwo::R{Bool} = false
    valthree::R{Bool} = false
    checks::R{Vector{Bool}} = falses(3)
    offsetchecks::R{OffsetVector{Bool, BitVector}} = OffsetArray(falses(3), -1)    
end

function ui(model)
    page(model, class = "container", [
        checkbox(label = "Apples", fieldname = :valone, dense = true),
        checkbox(label = "Bananas", fieldname = :valtwo, dense = true),
        checkbox(label = "Mangos", fieldname = :valthree, dense = true),
        separator(),
        [checkbox("Checkbox $i", Symbol("checks[$(i-1)]")) for i in 1:length(model.checks[])]...,
        separator(),
        [checkbox("Offset Checkbox $i", Symbol("offsetchecks[$i]")) for i in eachindex(model.offsetchecks[])]...
    ])
end

model = Stipple.init(Model)

route("/") do
    html(ui(model), context = @__MODULE__)
end

up(async = true)

model.valone[] = true
model.checks[2] = true
model.offsetchecks[2] = true