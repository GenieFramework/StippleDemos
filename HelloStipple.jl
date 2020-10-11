using Stipple

# Uncomment for autoreload functionality in the browser
# using GenieAutoReload
# autoreload(pwd())

Base.@kwdef mutable struct Name <: ReactiveModel
  name::R{String} = "Stipple!"
end

model = Stipple.init(Name())

function ui()
  [
    page(
      vm(model), class="container", title="Hello Stipple",
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
    # Uncomment for autoreload functionality in the browser
    # GenieAutoReload.assets()
  ] |> html
end

route("/", ui)

up(rand((8000:9000)), open_browser=true)