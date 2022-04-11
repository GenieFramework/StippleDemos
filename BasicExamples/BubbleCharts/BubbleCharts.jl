using Stipple, StipplePlotly

@reactive mutable struct Model <: ReactiveModel
  marker::PlotDataMarker =
    PlotDataMarker(opacity = [1, 0.8, 0.6, 0.4], size = [40, 60, 80, 100])

  title::PlotLayoutTitle = PlotLayoutTitle(text = "Marker Size")

  plotdata::R{PlotData} =
    PlotData(x = [1, 2, 3, 4], y = [10, 11, 12, 13], mode = "markers", marker = marker)

  layout::R{PlotLayout} =
    PlotLayout(title = title, showlegend = false, height = 600, width = 600)
end

function ui(model)
  [
    page(
      model,
      class = "container",
      title = "Bubble Chart",
      partial = true,
      [
        row(
          cell(
            class = "st-module",
            [plot(:plotdata, layout = :layout, config = "{ displayLogo:false }")],
          ),
        ),
      ],
    ),
  ]
end

route("/") do
  model = Model |> init
  html(ui(model), context = @__MODULE__)
end

up()
