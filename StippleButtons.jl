using Stipple
using StippleUI

# Uncomment for autoreload functionality in the browser
# using GenieAutoReload
# autoreload(pwd())

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
  # Uncomment for autoreload functionality in the browser
  # GenieAutoReload.assets()
  ]
end

route("/") do
  ui(model) |> html
end

up(rand((8000:9000)), open_browser=true)