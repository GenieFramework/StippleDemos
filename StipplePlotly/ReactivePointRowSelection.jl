using Stipple, StippleUI, StipplePlotly, PlotlyBase, DataFrames
import Stipple.table

register_mixin(@__MODULE__)

df = DataFrame(a = [1, 2, 4, 6, 8, 10], b = ["Hello", "world", ",", "hello", "sun", "!"])
pl = PlotlyBase.Plot(scatter(x = df.a, text = df.b))
datatable = DataTable(df)

@reactive! struct TableDemo <: ReactiveModel
    @mixin table::DataTableWithSelection(var"" = datatable)
    @mixin plot::PBPlotWithEvents(var"" = pl)
end

Genie.Router.delete!(:TableDemo)

model = init(TableDemo)

function handlers(model)
    on(model.isready) do isready
        isready || return
        push!(model)
    end

    on(model.plot_selected) do data
        selectrows!(model, :table, getindex.(data["points"], "pointIndex") .+ 1)
    end

    on(model.table_selection) do selection
        model.plot.data[1][:selectedpoints] = getindex.(selection, "__id") .- 1
        notify(model.plot)
    end

    return model
end

function ui(model)
    page(
        model,
        title = "Hello Stipple",
        cell([
            table(:table,  selection = "multiple", var":selected.sync" = "table_selection", pagination = :table_pagination)
            plotly(:plot, id = "plot")
        ])
    )
end

route("/") do
    # global model definition is for debugging/testing purpose only
    global model 
    model = init(TableDemo, debounce = 0)
    model |> handlers |> ui |> html
end

Stipple.js_mounted(::TableDemo) = watchplot(:plot, :plot)

up()