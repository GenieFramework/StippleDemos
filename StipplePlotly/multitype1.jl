using Genie, Genie.Renderer.Html, Stipple, StipplePlotly

Genie.config.log_requests = false

xrange = 0.0:(2π/1000):2π

dxmeasured = 0.05
dymeasured = 0.1

xexperiment = (0.0:(2π/10):2π) .+ 3 .* dxmeasured .* (rand(Float64,11) .- 0.5)
dx = dxmeasured .* ones(Float64, size(xexperiment))
yexperiment = sin.(xexperiment) .+ 3 .* dymeasured .* (rand(Float64,size(xexperiment)) .- 0.5)
dy = dymeasured .* ones(Float64, size(yexperiment))
# create outlier:
yexperiment[6] = 0.5

pd_line(name, xar) = PlotData(
  x = xar,
  y = sin.(xar),
  plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
  mode = "lines",
  name = name
)

pd_scatter(name, xar, dx, yar, dy) = PlotData(
  x = xar,
  error_x = ErrorBar(dx),
  y = yar,
  error_y = ErrorBar(dy),
  plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
  mode = "markers",
  name = name
)

pl() = PlotLayout(
  plot_bgcolor = "#FFFFFF",
  title = PlotLayoutTitle(text="Wave", font=Font(24)),
  legend = PlotLayoutLegend(bgcolor = "rgb(212,212,212)", font=Font(6)),
  hovermode = "closest",
  showlegend = true,
  xaxis = [PlotLayoutAxis(xy="x", index=1,
    title = "time (s)",
    ticks = "outside",
    tickfont = Font(size=24, color="#FF00FF"),
    showline = true,
    zeroline = false,
    mirror = true
  )],
  yaxis = [PlotLayoutAxis(xy="y", index=1,
    showline = true,
    zeroline = false,
    title = "displacement (mm)",
    ticks = "outside",
    mirror = true
  )],
  annotations = [PlotAnnotation(visible=true, x=xexperiment[6], y=yexperiment[6], text="possible outlier")]
)

Base.@kwdef mutable struct Model <: ReactiveModel
  data::R{Vector{PlotData}} = [pd_line("Sinus", xrange), pd_scatter("Experiment", xexperiment, dx, yexperiment, dy)]
  layout::R{PlotLayout} = pl()
  config::R{PlotConfig} = PlotConfig()
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
