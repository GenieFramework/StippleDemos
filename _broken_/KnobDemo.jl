using Stipple, StippleUI

Base.@kwdef mutable struct KnobDemo <: ReactiveModel

end

hs_model = Stipple.init(KnobDemo())

function ui()
  [
    page(
      vm(hs_model), class="container", title="Knob Demo", partial=true,
      [
        row(
          cell([
            knob(1:1:100)
          ])
        )
      ]
    )
  ] |> html
end

route("/", ui)

up(rand((8000:9000)), open_browser=true)