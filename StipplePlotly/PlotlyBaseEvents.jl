using Stipple, StipplePlotly
using PlotlyBase

@vars Example begin
    plot1::R{Plot} = Plot()
    plot1_selected::R{Dict{String, Any}} = Dict{String, Any}()
    plot1_hover::R{Dict{String, Any}} = Dict{String, Any}()

    plot2::R{Plot} = Plot()
    plot2_selected::R{Dict{String, Any}} = Dict{String, Any}()
    plot2_hover::R{Dict{String, Any}} = Dict{String, Any}()
end

Genie.Router.delete!(:Example)

function ui(model::Example)
    page(model, class = "container", 
    # append = script([
    #     watchplot("plot1", model),
    #     watchplot("plot2", model)
    # ]),
    row(class = "st-module", [
        plotly(:plot1, id = "plot1"),
        plotly(:plot2, id = "plot2")
    ]))
end

Stipple.js_mounted(::Example) = join([
    watchplot(:plot1),
    watchplot(:plot2)
])

model = init(Example, debounce=0)

route("/") do
    model |> handlers |> ui |> html
end

function handlers(model)
    on(model.isready) do isready
        isready || return
        push!(model)
    end

    on(model.plot1_selected) do data
        model.plot2.data[1][:selectedpoints] = getindex.(data["points"], "pointIndex")
        notify(model.plot2)
    end

    on(model.plot2_selected) do data
        model.plot1.data[1][:selectedpoints] = getindex.(data["points"], "pointIndex")
        notify(model.plot1)
    end

    on(model.plot1_selected) do data
        haskey(data, "points") && @info "Selection: $(getindex.(data["points"], "pointIndex"))"
    end

    return model
end

up(8000)

for i in 1:3
    model.plot1[] = Plot(scatter(y = rand(5)))
    model.plot2[] = Plot(scatter(y = rand(5)))
    sleep(0.1)
end