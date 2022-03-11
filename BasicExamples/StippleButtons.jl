using Stipple
using StippleUI

Base.@kwdef mutable struct SBModel <: ReactiveModel
  clicks::R{Int} = 0
  value::R{Int} = 0
end

const sb_model = Stipple.init(SBModel(), debounce = 0)

on(sb_model.value) do (_...)
  sb_model.clicks[] += 1
end

function ui(model::SBModel)
  [
    dashboard(
      vm(model),
      class = "container",
      title = "Buttons demo",
      [
        heading("Buttons")
        row(
          [
            cell([btn("Less! ", @click("value -= 1"))])
            cell(
              [
                p([
                  "Clicks: "
                  span(model.clicks, @text(:clicks))
                ])
                p([
                  "Value: "
                  span(model.value, @text(:value))
                ])
              ],
            )
            cell([btn("More! ", @click("value += 1"))])
          ],
        )
      ],
    ),
  ]
end

route("/") do
  ui(sb_model) |> html
end

up(rand((8000:9000)), open_browser = true)
