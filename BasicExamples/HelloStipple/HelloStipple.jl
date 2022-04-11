using Stipple, StippleUI
using Random, Genie.Sessions

Sessions.init()
@reactive! mutable struct Name <: ReactiveModel
  name::R{String} = ""
end

function ui(model)
  on(model.isready) do _
    model.name[] = Sessions.get!(:name, "")
  end

  on(model.name) do val
    Sessions.set!(:name, val) |> Sessions.persist
  end

  [
    page(
      model,
      title = "Hello Stipple",
      [
        h1([
          "Hello, "
          span([], @text(:name))
        ])
        p([
          "What is your name? "
          input("", placeholder = "Type your name", @bind(:name))
        ])
      ],
      @iif(:isready)
    ),
  ]
end

route("/") do
  init(Name) |> ui |> html
end

up()
