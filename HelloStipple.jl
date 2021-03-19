using Stipple
using StippleCharts

Base.@kwdef mutable struct Name <: ReactiveModel
  name::R{String} = "Stipple!"
  plot_options::PlotOptions = PlotOptions(chart_type=:pie, chart_width=380,
                                            stroke_show = false, plot_options_pie_size = 380,
                                            labels=["Team A", "Team B", "Team C", "Team D", "Team E"])
  piechart::R{Vector{Int}} = [44, 55, 13, 43, 22]
end

Stipple.register_components(Name, StippleCharts.COMPONENTS)

hs_model = Stipple.init(Name())

function ui()
  [
    page(
      vm(hs_model), class="container", title="Hello Stipple", partial=true,
      [
        row(
          cell([
            h1([
              "Hello, "
              span("", @text(:name))
            ])

            p([
              "What is your name? "
              input("", placeholder="Type your name", @bind(:name))
            ])
          ])
        )
        row(
          cell(class="st-module", [
            plot(@data(:piechart), options=:plot_options)
          ])
        )
      ]
    )
  ] |> html
end

route("/", ui)

up(rand((8000:9000)), open_browser=true)