using Stipple, StippleUI

# Genie.Secrets.secret_token!()

register_mixin(@__MODULE__)

# to be implemented in Stipple or Genie ...
function add_fileroute(assets_config::Genie.Assets.AssetsConfig, filename::AbstractString; 
    basedir = @__DIR__, content_type::Union{Nothing, Symbol} = nothing, type::Union{Nothing, String} = nothing, ext::Union{Nothing, String} = nothing, kwargs...)

    file, ex = splitext(filename)
    ext = isnothing(ext) ? ex : ext
    type = isnothing(type) ? ex[2:end] : type
    
    content_type = isnothing(content_type) ? if type == "js"
        :javascript
    elseif type == "css"
        :css
    elseif type in ["jpg", "jpeg", "svg", "mov", "avi", "png", "gif", "tif", "tiff"]
        imagetype = replace(type, Dict("jpg" => "jpeg", "mpg" => "mpeg", "tif" => "tiff")...)
        Symbol("image/$imagetype")
    else
        Symbol("*.*")
    end : content_type

    Genie.Router.route(Genie.Assets.asset_path(assets_config, type; file, ext, kwargs...)) do
        Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(cwd=basedir; type, file)),
        content_type) |> Genie.Renderer.respond
    end
end


add_fileroute(StippleUI.assets_config, "Sortable.min.js")
add_fileroute(StippleUI.assets_config, "vuedraggable.umd.min.js")
add_fileroute(StippleUI.assets_config, "vuedraggable.umd.min.js.map", type = "js")
add_fileroute(StippleUI.assets_config, "QSortableTree.js")

draggabletree_deps() = [
    script(src = "/stippleui.jl/master/assets/js/sortable.min.js")
    script(src = "/stippleui.jl/master/assets/js/vuedraggable.umd.min.js")
    script(src = "/stippleui.jl/master/assets/js/qsortabletree.js")
]

Stipple.DEPS[:qdraggabletree] = draggabletree_deps

draggabletree(nodes::Symbol; nodekey = "label", kwargs...) = quasar(:sortable__tree; nodes, node__key = get(kwargs, :node__key, nodekey), delete!(Dict(kwargs), :node__key)...)

dict(; kwargs...) = Dict{Symbol, Any}(kwargs...)

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

files = filedict(dirname(@__DIR__))
@reactive! struct DraggableTreeDemo <: ReactiveModel
    files::R{Vector{Dict{Symbol, Any}}} = [files]
end

Genie.Router.delete!(:DraggableTreeDemo)
Stipple.js_mounted(::DraggableTreeDemo) = ""

function handlers(model)
    on(model.isready) do isready
        isready || return
        push!(model)
    end

    return model
end

function ui(model)
    page(
        model,
        title = "Sortable Tree Demo",

        row(cell(class = "st-module", [
            h3("Implementation of " * a("mechanicalgux's QSortableTree", href = "https://gitlab.com/mechanicalgux/quasar-sortable-tree", style = "text-decoration: none"))
            row([
                cell(draggabletree(:files, nodes_key = "key"))
                cell(draggabletree(:files, nodes_key = "key"))
            ])
        ])),
        @iif(isready)
    )
end

route("/") do
    # global model definition is for debugging/testing purpose only
    global model 
    model = init(DraggableTreeDemo, debounce = 0)
    model |> handlers |> ui |> html
end

up()