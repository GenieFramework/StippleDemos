using Stipple
using StippleCharts

@vars HelloPie begin
  plot_options::R{PlotOptions} = PlotOptions(
    chart_type = :pie,
    chart_width = 380,
    chart_animations_enabled = true,
    stroke_show = false,
    labels = ["Slice A", "Slice B"],
  )
  piechart_::R{Vector} = Any[44, 55]
  values::R{String} = join(piechart_, ",")
end

Stipple.register_components(HelloPie, StippleCharts.COMPONENTS)

function random_color()::String
  string(rand(0:255), base = 16) |> uppercase
end

function ui(model)
  on(model.values) do _
    model.piechart_[] = Any[tryparse(Int, strip(x)) for x in split(model.values[], ',')]

    po = model.plot_options[]
    po.labels = ["Slice $x" for x in (collect('A':'Z')[1:length(model.piechart_[])])]

    while length(model.piechart_[]) > length(po.colors)
      push!(po.colors, string('#', random_color(), random_color(), random_color()))
    end

    model.plot_options[] = po
  end

  [
    page(
      model,
      class = "container",
      title = "Hello Pie",
      partial = true,
      [
        row(
          cell(
            [
              h1([
                "Your pie has the following slices: "
                span("", @text(:values))
              ])
              p(
                [
                  "Share your pie? (comma separated list of values) "
                  input("", placeholder = "Share your pie", @bind(:values))
                ],
              )
            ],
          ),
        )
        row(
          cell(class = "st-module", [plot(@data(:piechart_), options! = "plot_options")]),
        )
      ],
    ),
  ]
end

route("/") do
  HelloPie |> init |> ui |> html
end

up()
