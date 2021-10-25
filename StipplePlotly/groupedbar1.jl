using Genie, Genie.Renderer.Html, Stipple, StipplePlotly

Genie.config.log_requests = false

xx = ["start", "1d", "1w", "2w", "6w"]
spaces = "       "

# Data:

y1 = [98.5, 96.0, 95.1, 94.4, 94.0]
pb1 = PlotData(
    x = xx, y = y1, xaxis="x", yaxis="y",
    error_y = ErrorBar(3 .* ones(Float64,size(y1)); color="rgba(0,0,0,0.6)"),
    plot = StipplePlotly.Charts.PLOT_TYPE_BAR, name = "Product 1",
    text = spaces .* string.(y1), textposition="auto"
)

y2 = [99.5, 94.0, 93.1, 92.4, 92.0]
pb2 = PlotData(
    x = xx, y = y2, xaxis="x", yaxis="y",
    error_y = ErrorBar(3 .* ones(Float64,size(y1)); color="rgba(0,0,0,0.6)"),
    plot = StipplePlotly.Charts.PLOT_TYPE_BAR, name = "Product 2",
    text = spaces .* string.(y2), textposition="auto"
)

y3 = [97.5, 92.0, 92.1, 91.4, 91.0]
pb3 = PlotData(
    x = xx, y = y3, xaxis="x", yaxis="y",
    error_y = ErrorBar(3 .* ones(Float64,size(y1)); color="rgba(0,0,0,0.6)"),
    plot = StipplePlotly.Charts.PLOT_TYPE_BAR, name = "Product 3",
    text = spaces .* string.(y3), textposition="auto"
)

y4 = [92.5, 88.1, 87.1, 85.9, 84.0]
pb4 = PlotData(
    x = xx, y = y4, xaxis="x", yaxis="y",
    error_y = ErrorBar(3 .* ones(Float64,size(y1)); color="rgba(0,0,0,0.6)"),
    plot = StipplePlotly.Charts.PLOT_TYPE_BAR, name = "Product 4",
    text = spaces .* string.(y4), textposition="auto"
)

plotdata = [pb1, pb2, pb3, pb4]

layout = PlotLayout(barmode="group", font=Font(16),
    title = PlotLayoutTitle(text="Product comparison", font=Font(24)),
    xaxis = [PlotLayoutAxis(xy = "x", index = 1, title="duration", font=Font(size=24), showline = true, zeroline = false)],
    yaxis = [PlotLayoutAxis(xy = "y", index = 1, ticks = "outside", title="ratio (%)", font=Font(size=24), autorange=false, range=[70.0,100.0], showline = true, zeroline = false)]
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
