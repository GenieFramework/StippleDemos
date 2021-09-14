using Stipple, StippleUI

Base.@kwdef mutable struct KnotDemo <: ReactiveModel

end

hs_model = Stipple.init(KnotDemo())

function ui()
  [
    page(
      vm(hs_model), class="container", title="Knot Demo", partial=true,
      [
        row(
          cell([
            Knot Demo
          ])
        )
      ]
    )
  ] |> html
end

route("/", ui)

# up(rand((8000:9000)), open_browser=true)