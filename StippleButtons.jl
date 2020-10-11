using Genie
using Stipple
using StippleUI

using GenieAutoReload
autoreload(pwd())

Base.@kwdef mutable struct Model <: ReactiveModel
  clicks::R{Int} = 0
  value::R{Int} = 0
end

const model = Stipple.init(Model(), debounce = 0)

on(model.value) do (_...)
  model.clicks[] += 1
end

function ui(model::Model)
  [
  dashboard(
    vm(model), class="container", title="Buttons demo",
    [
      heading("Buttons")

      row([
        cell([
          btn("Less! ", @click("value -= 1"))
        ])
        cell([
          p([
              "Clicks: "
              span(model.clicks, @text(:clicks))
          ])
          p([
            "Value: "
            span(model.value, @text(:value))
          ])
        ])
        cell([
          btn("More! ", @click("value += 1"))
        ])
      ])
    ]
  )
  GenieAutoReload.assets()
  ]
end

route("/") do
  ui(model) |> html
end