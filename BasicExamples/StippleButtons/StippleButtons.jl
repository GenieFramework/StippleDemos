using Stipple
using StippleUI

@vars SBModel begin
  clicks::R{Int} = 0
  value::R{Int} = 0
end

function handler(model)
  on(model.value) do (_...)
    model.clicks[] += 1
  end
  model
end

function ui(model::SBModel)
  [
    page(model,
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
  model = SBModel |> init |> handler
  ui(model) |> html
end

up(rand((8000:9000)), open_browser = true)
