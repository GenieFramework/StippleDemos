using Stipple
using StippleUI
using GenieSession

@vars Name begin
  name::R{String} = ""
end

function handlers(model)
  on(model.isready) do _
    model.name[] = GenieSession.get!(:name, "")
  end

  on(model.name) do val
    GenieSession.set!(:name, val) |> GenieSession.persist
  end

  model
end

function ui(model)
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
  init(Name) |> handlers |> ui |> html
end

up()
