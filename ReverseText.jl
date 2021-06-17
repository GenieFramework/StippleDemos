using Stipple, StippleUI

Base.@kwdef mutable struct RTModel <: ReactiveModel
  process::R{Bool} = false
  output::R{String} = ""
  input::R{String} = "Stipple"
end

rt_model = Stipple.init(RTModel())

on(rt_model.process) do _
  if (rt_model.process[])
    rt_model.output[] = rt_model.input[] |> reverse
    rt_model.process[] = false
  end
end

function ui()
  [
  page(
    vm(rt_model), class="container", title="Reverse text", [
      p([
        "Input "
        input("", @bind(:input), @on("keyup.enter", "process = true"))
      ])
      p(
        button("Reverse", @click("process = true"))
      )
      p([
        "Output: "
        span("", @text(:output))
      ])
    ]
  )
  ] |> html
end

route("/", ui)

up(rand((8000:9000)), open_browser=true)