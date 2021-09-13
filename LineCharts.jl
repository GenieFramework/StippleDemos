using Stipple, StippleCharts

@kwredef struct ChartData <: ReactiveModel
  plot_options = PlotOptions(chart_type=:line, chart_sparkline_enabled=true, chart_width=100, chart_height=75,
                              grid_show=false, grid_row_opacity = 0)
  d = PlotData(44, 55, 122, 10, 34)
end

Stipple.register_components(ChartData, StippleCharts.COMPONENTS)

function ui()
  [
    page(
      vm(ChartData() |> Stipple.init), class="container", title="Line Charts",
      [
        row(
          cell(class="st-module", [
            plot(@data(:d), options=:plot_options, width=100, height=70)
          ])
        )
      ]
    )
  ] |> html
end

route("/", ui)

up(rand((8000:9000)), open_browser=true)