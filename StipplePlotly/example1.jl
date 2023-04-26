using Stipple, StippleUI, StipplePlotly

#=== config ==#

for m in [Genie, Stipple, StippleUI, StipplePlotly]
  m.assets_config.host = "https://cdn.statically.io/gh/GenieFramework"
end

# WEB_TRANSPORT = Genie.WebChannels #Genie.WebThreads #

#== data ==#

pd(name) = PlotData(
  x = ["Jan2019", "Feb2019", "Mar2019", "Apr2019", "May2019",
        "Jun2019", "Jul2019", "Aug2019", "Sep2019", "Oct2019",
        "Nov2019", "Dec2019"],
  y = Int[rand(1:100_000) for x in 1:12],
  plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
  name = name
)

#== reactive model ==#

@vars Model begin
  data::R{Vector{PlotData}} = [pd("Random 1"),pd("Random 2")]
  layout::R{PlotLayout} = PlotLayout(
      plot_bgcolor = "#333",
      title = PlotLayoutTitle(text="Random numbers", font=Font(24))
    )
  config::R{PlotConfig} = PlotConfig()
end

#== ui ==#

function ui(model)
  page(model,
    class="container", [
      heading("Plotly example")

      row([
        cell(class="st-module", [
          h6("Plot of random values")
          plot(:data, layout = :layout, config = :config)
        ])
      ])
    ]
  )
end

#== server ==#

route("/") do
  Stipple.init(Model) |> ui |> html
end

up()
