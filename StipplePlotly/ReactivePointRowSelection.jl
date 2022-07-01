using Stipple, StippleUI, StipplePlotly, PlotlyBase, DataFrames
import Stipple.table

register_mixin(@__MODULE__)

df = DataFrame(a = [1, 2, 4, 6, 8, 10], b = ["Hello", "world", ",", "hello", "sun", "!"])
pl = PlotlyBase.Plot(scatter(x = df.a, text = df.b))
datatable = DataTable(df)

@reactive! struct TableDemo <: ReactiveModel
    @mixin table::DataTableWithSelection(var"" = DataTable(copy(df)))
    @mixin plot::PBPlotWithEvents(var"" = copy(pl))
    showplot::R{Bool} = true
end

Genie.Router.delete!(:TableDemo)
Stipple.js_mounted(::TableDemo) = watchplots()

function handlers(model)
    on(model.isready) do isready
        isready || return
        push!(model)
    end

    on(model.plot_selected) do data
        selectrows!(model, :table, getindex.(data["points"], "pointIndex") .+ 1)
    end

    # the commented lines show a version that changes data on the backend first and then
    # updates the full plot. That redraws the plot completely and resets the mode to default.
    # So you will be in zoom-mode again, even if you were in select-mode before.
    # The active version needs at least Stipple v0.24.2
    on(model.table_selection) do selection
        ii = getindex.(selection, "__id") .- 1
        model["plot.data[0].selectedpoints"] = isempty(ii) ? nothing : ii
        # model.plot.data[1][:selectedpoints] = isempty(ii) ? nothing : ii

        notify(model, js"plot.data")
        # notify(model.plot)
    end

    return model
end

function ui(model)
    page(
        model,
        title = "Hello Stipple",
        row(cell(class = "st-module",[
            table(:table,  selection = "multiple", var":selected.sync" = "table_selection", pagination = :table_pagination)
            toggle("Show plot", :showplot)
            plotly(:plot, @iif("showplot"), syncevents = true)
        ])),
        @iif(isready)
    )
end

route("/") do
    # global model definition is for debugging/testing purpose only
    global model 
    model = init(TableDemo, debounce = 0)
    model |> handlers |> ui |> html
end

up()