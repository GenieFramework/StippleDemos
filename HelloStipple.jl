using Stipple

Base.@kwdef mutable struct Name <: ReactiveModel
  name::R{String} = "Stipple!"
end

hs_model = Stipple.init(Name())

function ui()
  [
    page(
      vm(hs_model), class="container", title="Hello Stipple",
      [
        h1([
          "Hello, "
          span("", @text(:name))
        ])

        p([
          "What is your name? "
          input("", placeholder="Type your name", @bind(:name))
        ])
      ]
    )
  ] |> html
end

route("/", ui)

up(rand((8000:9000)), open_browser=true)