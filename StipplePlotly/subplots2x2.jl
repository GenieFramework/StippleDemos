using Genie, Genie.Renderer.Html, Stipple, StipplePlotly

Genie.config.log_requests = false

xx = -π:(2π/250):π

xxs = -3.0:0.2:3.0

# Data:

pl1 = PlotData(
    x = xx, y = sin.(xx), plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "sine", mode = "lines", xaxis = "x", yaxis = "y", line = PlotlyLine(color = "rgb(0,0,192)", dash="solid")
)

pl2 = PlotData(
    x = xx, y = sinh.(xx), plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "sinh", mode = "lines", xaxis = "x2", yaxis = "y2", line = PlotlyLine(color = "rgb(0,192,0)", dash="dot")
)

pl3 = PlotData(
    x = xx, y = cos.(xx), plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "cosine", mode = "lines", xaxis = "x3", yaxis = "y3", line = PlotlyLine(color = "rgb(192,0,0)", dash="dash")
)

pl4 = PlotData(
    x = xx, y = cosh.(xx), plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "cosh", mode = "lines", xaxis = "x4", yaxis = "y4", line = PlotlyLine(color = "rgb(192,0,192)", dash="dashdot")
)

ps1 = PlotData(
    x = xxs, y = sin.(xxs) .+ rand(Float64, size(xxs)) .- 0.5, plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "sine", mode = "markers", xaxis = "x", yaxis = "y", marker = PlotDataMarker(color="rgb(0,0,192)", symbol="circle", size=10, opacity=0.5)
)

ps2 = PlotData(
    x = xxs, y = sinh.(xxs) .+ 3.0 .* rand(Float64, size(xxs)) .- 1.5, plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "sinh", mode = "markers", xaxis = "x2", yaxis = "y2", marker = PlotDataMarker(color = "rgb(0,192,0)", symbol="circle-open", size=14)
)

ps3 = PlotData(
    x = xxs, y = cos.(xxs) .+ rand(Float64, size(xxs)) .- 0.5, plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "cosine", mode = "markers", xaxis = "x3", yaxis = "y3", marker = PlotDataMarker(color = "rgb(192,0,0)", symbol="diamond", size=10, opacity=0.5)
)

ps4 = PlotData(
    x = xxs, y = cosh.(xxs) .+ 3.0 .* rand(Float64, size(xxs)) .- 1.5, plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name = "cosh", mode = "markers", xaxis = "x4", yaxis = "y4", marker = PlotDataMarker(color = "rgb(192,0,192)", symbol="diamond-open", size=3)
)

plotdata = [ps1, ps2, ps3, ps4, pl1, pl2, pl3, pl4];

# Layout

layout = PlotLayout(
    title = PlotLayoutTitle(text="Multiple Mixed Subplots", font=Font(24)),
    showlegend = false,
    grid = PlotLayoutGrid(rows = 2, columns = 2, pattern = "independent"),
    xaxis = [
        PlotLayoutAxis(xy = "x", index = 1, ticks = "outside", showline = true, zeroline = false),
        PlotLayoutAxis(xy = "x", index = 2, ticks = "outside", showline = true, zeroline = false),
        PlotLayoutAxis(xy = "x", index = 3, ticks = "outside", showline = true, zeroline = false, title="range (arb. units)"),
        PlotLayoutAxis(xy = "x", index = 4, ticks = "outside", showline = true, zeroline = false, title="range (arb. units)")
    ],
    yaxis = [
        PlotLayoutAxis(xy = "y", index = 1, ticks = "outside", showline = true, zeroline = false, title="response A"),
        PlotLayoutAxis(xy = "y", index = 2, ticks = "outside", showline = true, zeroline = false, title="response B"),
        PlotLayoutAxis(xy = "y", index = 3, ticks = "outside", showline = true, zeroline = false, title="response C"),
        PlotLayoutAxis(xy = "y", index = 4, ticks = "outside", showline = true, zeroline = false, title="response D")
    ],
)

Base.@kwdef mutable struct Model <: ReactiveModel
  data::R{Vector{PlotData}} = plotdata, READONLY
  layout::R{PlotLayout} = layout, READONLY
  config::R{PlotConfig} = PlotConfig(), READONLY
end

model = Stipple.init(Model())

function ui()
  page(
    vm(model), class="container", [
        plot(:data, layout = :layout, config = :config)
    ]
  ) |> html
end

route("/", ui)

up()
