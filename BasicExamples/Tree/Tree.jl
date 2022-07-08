using Stipple, StippleUI

dict(;kwargs...) = Dict{Symbol, Any}(kwargs...)
const mydiv = Genie.Renderer.Html.div

function filedict(startfile)
    if isdir(startfile)
        files = readdir(startfile, join = true)
        index = isdir.(files)
        files = vcat(files[index], files[.! index])
        dict(
            label = basename(startfile),
            key = startfile,
            icon = "folder",
            children = filedict.(files)
        )
    else
        dict(label = basename(startfile),
            key = startfile,
            icon = "insert_drive_file"
        )
    end
end

cd(dirname(@__DIR__))

@reactive! mutable struct TreeDemo <: ReactiveModel
    name::R{String} = ""
    files::R{Vector{Dict{Symbol, Any}}} = [filedict(pwd())]
    files_selected::R{Vector{String}} = String[]
    files_ticked::R{Any} = nothing
    files_expanded::R{Any} = nothing
end

Genie.Router.delete!(:TreeDemo)

function ui(model)
    page(
        model,
        title = "Hello Stipple",
        [
            quasar(:tree, var"node-key" = "key", nodes = :files,
                var"tick-strategy"="leaf",
                var"selected.sync" = :files_selected,
                var"ticked.sync" = :files_ticked,
                var"expanded.sync" = :files_expanded
            )

            mydiv("Ticked: {{ files_selected }}")
            mydiv("Expanded: {{ files_expanded }}")
            mydiv("Selected: {{ files_ticked }}")
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
    global model
    model = init(TreeDemo) |> handlers
    model |> ui |> html
end

up()
