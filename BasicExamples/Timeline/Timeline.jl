using Stipple
using StippleUI
using DataFrames

Stipple.render(df::DataFrames.DataFrame, fieldname::Union{Nothing, Symbol} = nothing) = Dict(zip(names(df), eachcol(df)))

@vars TimeSeries begin
    button_pressed = false
    df = DataFrame(:Title => ["Title A", "Title B"], :Message => ["message 1", "message 2"]), READONLY
    private = "private", PRIVATE
    nonreactive = "nr", NON_REACTIVE
end

function ui(model)
    page(
        model,
        class = "container",
        row(cell(class = "st-module", [
            btn("Update Timeline", color = "primary", @click("button_pressed = true"))
            timeline("", color = "primary", [
                timelineentry("Timeline", heading = true),
                timelineentry("{{ df.Message[index] }}", @recur("(t, index) in df.Title"), title = :t)
            ])
        ])),
    )
end

function handlers(model)
    on(model.isready) do ready
        ready || return
        push!(model)
    end
    
    onbutton(model.button_pressed) do
        @show "Button Pressed"
        model.df[] = DataFrame(:Title => ["Title C", "Title D", "Title E"], :Message => ["message 3", "message 4", "message 5"])
    end

    model
end


route("/") do
    model = TimeSeries |> init |> handlers
    model |> ui |> html
end

up()