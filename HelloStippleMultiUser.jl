using Stipple

Base.@kwdef mutable struct Name <: ReactiveModel
  name::R{String} = "Stipple!"
end

hs_models = Dict{String,Name}()

function ui()
  channel = String(@params(:session_id))
  hs_model = if haskey(hs_models, channel)
    hs_models[channel]
  else
    hs_models[channel] = Stipple.init(Name(), channel = channel)
  end

  on(hs_models[channel].name) do _
    @show "changed"
  end

  [
    page(
      vm(hs_model), class="container", title="Hello Stipple", partial=true, channel=channel,
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

route("/") do
  Stipple.Genie.Renderer.redirect("/dashboards/$(rand(10_000:99_999))")
end

route("/dashboards/:session_id", ui)

up(rand((8000:9000)), open_browser=true)