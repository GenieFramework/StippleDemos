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
add_fileroute(StippleUI.assets_config, "QDraggableTree.js")

draggabletree_deps() = [
    script(src = "/stippleui.jl/master/assets/js/sortable.min.js")
    script(src = "/stippleui.jl/master/assets/js/vuedraggable.umd.min.js")
    script(src = "/stippleui.jl/master/assets/js/qdraggabletree.js")
]

Stipple.DEPS[:qdraggabletree] = draggabletree_deps

draggabletree(fieldname::Symbol; data::Union{Symbol, String} = fieldname, rowkey = "key", kwargs...) = quasar(:draggable__tree; fieldname, data, row__key = rowkey, kwargs...)

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

files = filedict(dirname(dirname(@__DIR__)))
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
        title = "Draggable Tree Demo",

        row(cell(class = "st-module", [
            h3("Adaptation from " * a("Mayank Patel's QDraggableTree Demo", href = "https://codepen.io/mayank091193/pen/pogEjVK", style = "text-decoration: none"))

            row([
                cell(draggabletree(:files, rowkey = "key", group = "test"))
                cell(draggabletree(:files, rowkey = "key", group = "test"))
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