using Stipple, StippleUI

const MAX_BUTTONS = 10 # allow for a maximum of 10 buttons

function generate_buttons() # returns the array of button-labels (and functions)
  n = rand(1:MAX_BUTTONS) # choose a random number of buttons
  map(1:n) do i
    label = string(i) # the label of the button
    label # skipping the function part for now
    # click = _ -> println("You pressed on ", label) # run this function owhen the button is clicked
    # (; label, click)
  end
end

Base.@kwdef mutable struct DynamicContent <: ReactiveModel
  generate::R{Int} = 0 # pressing this will update the array of buttons
  buttons::R{Vector} = Any[]
end

function restart()
  global model
  println("Test")
  model = Stipple.init(DynamicContent(), debounce = 1)
  on(model.generate) do _
    model.buttons[] = generate_buttons()
  end

  on(model.buttons) do labels
    println(labels) # replace this to something that generates the buttons
  end
end

function ui()
  dashboard(
    vm(model),
    [
      heading("DynamicContent"),
      row(
        cell(
          class = "st-module",
          [p(button("Generate new buttons", @click("generate += 1")))],
        ),
      ),
    ],
    title = "DynamicContent",
  ) |> html
end

route("/", ui)
Genie.config.server_host = "127.0.0.1"
restart()
