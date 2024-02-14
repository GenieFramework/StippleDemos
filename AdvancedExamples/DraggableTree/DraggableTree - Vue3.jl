using Stipple, Stipple.ReactiveTools
using StippleUI

import Stipple.opts

cd(@__DIR__)
sortable_asset = Genie.Assets.add_fileroute(StippleUI.assets_config, "Sortable.min.js").path
draggablenext_asset = Genie.Assets.add_fileroute(StippleUI.assets_config, "vue-draggable-next.global.js").path

draggabletree_deps() = [
    script(src = sortable_asset)
    script(src = draggablenext_asset)
]

Stipple.deps!(Stipple, draggabletree_deps)
include(joinpath(@__DIR__, "sortable_components.jl"))

draggable(args...; kwargs...) = xelem(:draggable, args...; kwargs...)
draggabletree(fieldname::Symbol; key = "label", kwargs...) = quasar(:draggable__tree; fieldname, data = get(kwargs, :data, fieldname), delete!(Dict(kwargs), :data)...)

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
        dict(
            label = basename(startfile),
            key = startfile,
            icon = "insert_drive_file",
            children = []
        )
    end
end

files = filedict(dirname(@__DIR__))
@app DraggableTreeDemo begin
    @in files = [files]
    @in myList = [dict(id = i, name = n) for (i, n) in enumerate(["hello", "John", "Doe"])]
    @in element = ""
end

delete!(Stipple.COMPONENTS, DraggableTreeDemo)

Stipple.register_components(DraggableTreeDemo, ["draggable" => "VueDraggableNext.VueDraggableNext"])
Stipple.register_components(DraggableTreeDemo, qsortable_components())

const UI = Ref(ParsedHTMLString[]) 

UI[] = [
    row(cell(class = "st-module", [
        h6("Demo of a draggable list")
        draggable(fieldname = :myList,
            htmldiv(@for("element in myList"), key=R"element.id",
                "{{element.name}}"
            )
        )
    ]))
    
    row(cell(class = "st-module", [
        h6("Implementation of Mayank Patel's " * a("QDraggableTree", href = "https://github.com/mayank091193/quasar-draggable-tree/tree/next", style = "text-decoration: none"))
        draggabletree(:files, rowKey = "key")
    ]))    
]

ui() = UI[]


@page("/", ui, model = DraggableTreeDemo, debounce = 0)

up()