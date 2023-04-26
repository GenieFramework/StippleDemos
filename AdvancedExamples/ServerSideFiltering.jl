using Pkg
pkg"activate"
cd(@__DIR__)

using Stipple
using StippleUI

import Stipple: js_methods

using Random

@vars Example begin
    select::R{Vector{String}} = String[]
    options::R{Vector{String}} = ["Options 1", "Options 2", "Options 3"]
    filter::R{String} = ""
end

js_methods(::Example) = """
    filterFn (val, update, abort) {
        console.log('Filtering started!')
        update(() => {
            this.filter = val
        })
    },

    filterAbortFn () {
        console.log('Filtering aborted!')
    }
"""

row_module(args...; kwargs...) = row(cell(class="st-module", args...; kwargs...))

function ui(model)
    page(model, class="container", title="Example", [
        heading(string(row([
            a(icon("help", size = "xl", style = "width: auto"), href = "/"),
            cell(class = "text-h2", style ="padding-left: 20px", "Server-side filtering")
        ]))),

        row_module([
            Stipple.select(
                :select, options = :options, label = "Options", "", 
                :multiple, :use__chips, :options__dense,
                :use__input,
                @on(:filter, "filterFn"),
                @on(:filter, "filterAbortFn")
            )    
        ])
    ])
end

route("/") do
    init(Example) |> handlers |> ui|> html
end

function handlers(model)
    on(model.filter) do filter
        if isempty(filter)
            model.options[] = "Option " .* string.(1:10)
        elseif length(filter) > 2
            model.options[] = filter .* "_" .* [join([randstring(rand(2:5)) for _ in 1:3], "_") for _ in 1:10]
        end
    end

    model
end

up(8080, open_browser=true)
