# Note: use Stipple#master and StippleUI#master
# pkg> add Stipple#master StippleUI#master to run this demo

using Stipple, StippleUI
import Stipple.Html: div

function handlers(model)
  on(model.refresh) do val
    val || return
    model.url[] = "https://placeimg.com/500/300/nature?t=" * string(rand())
    model.refresh[] = false
  end

  model
end

@reactive mutable struct Model <: ReactiveModel
  url::R{String} = "https://placeimg.com/500/300/nature"
  refresh::R{Bool} = false
end

function ui(model)
  page(
    model,
    partial = true,
    [
      heading("Image Gallery")
      row([
        div(
          class = "q-pa-md col",
          [
            btn(
              color = "teal",
              label = "Change image",
              click!! = "refresh=true",
              class = "q-mb-md",
            )
            div(
              class = "q-gutter-sm row items-start",
              [
                imageview(
                  src = :url,
                  spinnercolor = "white",
                  style = "height: 140px; max-width: 150px",
                )
                imageview(
                  src = :url,
                  spinnercolor = "primary",
                  spinnersize = "82px",
                  style = "height: 140px; max-width: 150px",
                )
                imageview(
                  src = :url,
                  style = "height: 140px; max-width: 150px",
                  [
                    template(
                      "",
                      "v-slot:loading",
                      [spinner(:gears, color = "white")],
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ])
    ],
  )
end

route("/") do
  model = Model |> init |> handlers

  html(ui(model), context = @__MODULE__)
end

up()
