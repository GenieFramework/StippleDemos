using Stipple, StippleUI
using OrderedCollections

ld(;kwargs...) = LittleDict{Symbol, Any}(kwargs...)

function filedict(startfile)
    if isdir(startfile)
        files = readdir(startfile, join = true)
        index = isdir.(files)
        files = vcat(files[index], files[.! index])
        ld(
            label = basename(startfile),
            key = startfile,
            icon = "folder",
            children = filedict.(files)
        )
    else
        ld(label = basename(startfile),
            key = startfile,
            icon = "insert_drive_file"
        )
    end
end

cd(dirname(@__DIR__))

@reactive! mutable struct Name <: ReactiveModel
    name::R{String} = ""
    files::R{Vector{Dict{Symbol, Any}}} = [filedict(pwd())]
end


function ui(model)
    page(
        model,
        title = "Hello Stipple",
        [
            quasar(:tree, var"node-key" = "key", nodes = :files)
        ],
    )
end

function handlers(model)
    on(model.isready) do isready
        isready && push!(model)
    end

    model
end

route("/") do
    model = init(Name) |> handlers
    model |> ui |> html
end

up()
